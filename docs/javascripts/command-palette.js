/*
 * Ctrl+K / Cmd+K command palette.
 *
 * Searches the real MkDocs search index (search/search_index.json) by page
 * title, KB id and section, and offers a few navigation actions. No external
 * dependencies; implements the WAI-ARIA combobox + listbox pattern.
 */
(function () {
  "use strict";

  var SECTIONS = [
    { prefix: "kb/", label: "Knowledge Base" },
    { prefix: "tickets/", label: "Incidents" },
    { prefix: "scripts/", label: "Diagnostics" },
    { prefix: "processes/", label: "SLA & Processes" },
    { prefix: "tools-ticketing", label: "SLA & Processes" },
    { prefix: "infrastructure", label: "Infrastructure & Lab" },
    { prefix: "lab-plan", label: "Infrastructure & Lab" },
    { prefix: "decisions", label: "About" },
    { prefix: "design-system", label: "About" }
  ];
  var MAX_RESULTS = 40;

  var base = (function () {
    try {
      var cfg = JSON.parse(document.getElementById("__config").textContent);
      return new URL(cfg.base.replace(/\/?$/, "/"), location.href).href;
    } catch (e) {
      return new URL("./", location.href).href;
    }
  })();

  var pages = null; // loaded lazily on first open
  var results = [];
  var active = 0;
  var lastFocus = null;
  var backdrop, input, list, status;

  function sectionOf(location) {
    for (var i = 0; i < SECTIONS.length; i++) {
      if (location.indexOf(SECTIONS[i].prefix) === 0) return SECTIONS[i].label;
    }
    return "Overview";
  }

  function idOf(title) {
    var m = /^(KB|TCK)-\d{3}/.exec(title);
    return m ? m[0] : "";
  }

  function loadIndex() {
    if (pages) return Promise.resolve(pages);
    return fetch(base + "search/search_index.json")
      .then(function (r) {
        if (!r.ok) throw new Error("HTTP " + r.status);
        return r.json();
      })
      .then(function (data) {
        var seen = {};
        pages = [];
        data.docs.forEach(function (d) {
          if (d.location.indexOf("#") !== -1 || seen[d.location] || d.location === "404.html") return;
          seen[d.location] = true;
          var title = (d.title || "").replace(/<[^>]+>/g, "");
          // KB pages: prefix the id parsed from the URL so "KB-010" is searchable.
          var kb = /^kb\/kb-(\d{3})-/.exec(d.location);
          var id = kb ? "KB-" + kb[1] : idOf(title);
          pages.push({
            kind: "page",
            id: id,
            title: title.replace(/^TCK-\d{3}:\s*/, ""),
            section: sectionOf(d.location),
            href: base + d.location,
            haystack: (id + " " + title + " " + sectionOf(d.location) + " " + d.location).toLowerCase()
          });
        });
        return pages;
      });
  }

  function actions() {
    return [
      {
        kind: "action", id: "", title: "Toggle light / dark theme", section: "Action",
        haystack: "toggle theme dark light mode", run: function () {
          // Material renders one radio + label per scheme; the label after the
          // checked radio switches to the next scheme.
          var form = document.querySelector("[data-md-component=palette]");
          if (!form) return;
          var current = form.querySelector("input:checked") || form.querySelector("input");
          var label = current && current.nextElementSibling;
          if (label && label.tagName === "LABEL") label.click();
        }
      },
      {
        kind: "action", id: "", title: "Full-text search (search bar)", section: "Action",
        haystack: "full text search find", run: function () {
          var q = document.querySelector("[data-md-component=search-query]");
          var toggle = document.querySelector("[data-md-toggle=search]");
          if (toggle) toggle.checked = true;
          if (q) { q.value = input.value; q.dispatchEvent(new Event("input")); q.focus(); }
        }
      },
      {
        kind: "action", id: "", title: "Open source repository on GitHub", section: "Action",
        haystack: "github repository source code", href: "https://github.com/lucaswsanchez/helpdesk-kb"
      }
    ];
  }

  function score(item, terms) {
    var s = 0;
    for (var i = 0; i < terms.length; i++) {
      var pos = item.haystack.indexOf(terms[i]);
      if (pos === -1) return -1;
      s += pos === 0 ? 3 : 1;
      if (item.id && item.id.toLowerCase() === terms[i]) s += 10;
    }
    return s;
  }

  function filter(query) {
    var all = (pages || []).concat(actions());
    var terms = query.toLowerCase().split(/\s+/).filter(Boolean);
    if (!terms.length) {
      // Default view: actions first, then pages in site order.
      return actions().concat((pages || []).slice(0, MAX_RESULTS));
    }
    return all
      .map(function (item) { return { item: item, s: score(item, terms) }; })
      .filter(function (x) { return x.s >= 0; })
      .sort(function (a, b) { return b.s - a.s; })
      .slice(0, MAX_RESULTS)
      .map(function (x) { return x.item; });
  }

  function render() {
    results = filter(input.value);
    list.innerHTML = "";
    if (!results.length) {
      var empty = document.createElement("li");
      empty.className = "cmdk__empty";
      empty.setAttribute("role", "presentation");
      empty.textContent = pages ? "No matching pages. Press Enter to run a full-text search." : "Loading index…";
      list.appendChild(empty);
      input.removeAttribute("aria-activedescendant");
      status.textContent = pages ? "No results" : "";
      return;
    }
    var lastGroup = null;
    results.forEach(function (r, i) {
      var group = r.kind === "action" ? "Actions" : r.section;
      if (group !== lastGroup) {
        var g = document.createElement("li");
        g.className = "cmdk__group";
        g.setAttribute("role", "presentation");
        g.textContent = group;
        list.appendChild(g);
        lastGroup = group;
      }
      var li = document.createElement("li");
      li.className = "cmdk__item";
      li.id = "cmdk-opt-" + i;
      li.setAttribute("role", "option");
      li.setAttribute("aria-selected", i === active ? "true" : "false");
      var id = document.createElement("span");
      id.className = "cmdk__id";
      id.textContent = r.id || (r.kind === "action" ? ">" : "");
      var title = document.createElement("span");
      title.className = "cmdk__title";
      title.textContent = r.title;
      li.appendChild(id);
      li.appendChild(title);
      li.addEventListener("mousedown", function (e) { e.preventDefault(); });
      li.addEventListener("click", function () { active = i; choose(); });
      li.addEventListener("mousemove", function () { if (active !== i) { active = i; highlight(); } });
      list.appendChild(li);
    });
    highlight();
    status.textContent = results.length + " result" + (results.length === 1 ? "" : "s");
  }

  function highlight() {
    var items = list.querySelectorAll(".cmdk__item");
    for (var i = 0; i < items.length; i++) {
      items[i].setAttribute("aria-selected", i === active ? "true" : "false");
    }
    var el = document.getElementById("cmdk-opt-" + active);
    if (el) {
      input.setAttribute("aria-activedescendant", el.id);
      el.scrollIntoView({ block: "nearest" });
    }
  }

  function choose() {
    var r = results[active];
    if (!r) {
      if (input.value.trim()) actions()[1].run();
      close(false);
      return;
    }
    close(!!r.run);
    if (r.run) r.run();
    else if (r.href) location.href = r.href;
  }

  function open() {
    if (!backdrop) build();
    lastFocus = document.activeElement;
    backdrop.hidden = false;
    input.setAttribute("aria-expanded", "true");
    input.value = "";
    active = 0;
    render();
    input.focus();
    loadIndex().then(render).catch(function () {
      list.innerHTML = '<li class="cmdk__empty" role="presentation">Could not load the search index.</li>';
    });
  }

  function close(keepFocusAway) {
    if (!backdrop || backdrop.hidden) return;
    backdrop.hidden = true;
    input.setAttribute("aria-expanded", "false");
    if (!keepFocusAway && lastFocus && lastFocus.focus) lastFocus.focus();
  }

  function build() {
    backdrop = document.createElement("div");
    backdrop.className = "cmdk-backdrop";
    backdrop.hidden = true;
    backdrop.innerHTML =
      '<div class="cmdk" role="dialog" aria-modal="true" aria-label="Command palette">' +
      '<input class="cmdk__input" type="text" role="combobox" aria-expanded="false" aria-controls="cmdk-list" ' +
      'aria-autocomplete="list" aria-label="Search pages and commands" placeholder="Jump to an article, case, script or command…" autocomplete="off" spellcheck="false">' +
      '<ul class="cmdk__list" id="cmdk-list" role="listbox" aria-label="Results"></ul>' +
      '<div class="cmdk__footer" aria-hidden="true"><span>↑↓ navigate</span><span>↵ open</span><span>esc close</span></div>' +
      '<div class="cmdk__sr" role="status" aria-live="polite"></div>' +
      "</div>";
    document.body.appendChild(backdrop);
    input = backdrop.querySelector(".cmdk__input");
    list = backdrop.querySelector(".cmdk__list");
    status = backdrop.querySelector("[role=status]");

    backdrop.addEventListener("mousedown", function (e) { if (e.target === backdrop) close(false); });
    input.addEventListener("input", function () { active = 0; render(); });
    input.addEventListener("keydown", function (e) {
      if (e.key === "ArrowDown") { e.preventDefault(); active = Math.min(active + 1, results.length - 1); highlight(); }
      else if (e.key === "ArrowUp") { e.preventDefault(); active = Math.max(active - 1, 0); highlight(); }
      else if (e.key === "Home") { e.preventDefault(); active = 0; highlight(); }
      else if (e.key === "End") { e.preventDefault(); active = results.length - 1; highlight(); }
      else if (e.key === "Enter") { e.preventDefault(); choose(); }
      else if (e.key === "Escape") { e.preventDefault(); close(false); }
      else if (e.key === "Tab") { e.preventDefault(); } // keep focus inside the dialog
    });
  }

  function addTrigger() {
    var isMac = /Mac|iPhone|iPad/.test(navigator.platform || navigator.userAgent);
    var shortcut = isMac ? "⌘K" : "Ctrl K";
    var header = document.querySelector(".md-header__inner");
    var anchor = header && header.querySelector(".md-header__source");
    if (header && !header.querySelector(".cmdk-trigger")) {
      var btn = document.createElement("button");
      btn.type = "button";
      btn.className = "cmdk-trigger";
      btn.setAttribute("aria-label", "Open command palette (" + shortcut + ")");
      btn.innerHTML = '<span class="cmdk-trigger__label">Commands</span><kbd>' + shortcut + "</kbd>";
      btn.addEventListener("click", open);
      header.insertBefore(btn, anchor || null);
    }
    // In-page buttons (e.g. on the overview) can open the palette too.
    document.querySelectorAll("[data-cmdk-open]").forEach(function (el) {
      el.addEventListener("click", open);
      var k = el.querySelector("kbd");
      if (k) k.textContent = shortcut;
    });
  }

  document.addEventListener("keydown", function (e) {
    if ((e.ctrlKey || e.metaKey) && !e.altKey && (e.key === "k" || e.key === "K")) {
      e.preventDefault();
      if (backdrop && !backdrop.hidden) close(false);
      else open();
    }
  });

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", addTrigger);
  else addTrigger();
})();
