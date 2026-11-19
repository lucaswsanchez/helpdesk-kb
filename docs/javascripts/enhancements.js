/*
 * Small progressive enhancements on top of Material for MkDocs.
 * Everything works without this script; it only improves presentation.
 */
(function () {
  "use strict";

  /* Mermaid diagrams: wrap each one in a scroll container so that on phones
     the diagram keeps a legible size and scrolls sideways instead of shrinking
     until the labels are unreadable. */
  function wrapDiagrams() {
    document.querySelectorAll(".md-typeset .mermaid").forEach(function (el) {
      if (el.parentElement && el.parentElement.classList.contains("diagram-scroll")) return;
      var wrap = document.createElement("div");
      wrap.className = "diagram-scroll";
      wrap.setAttribute("role", "region");
      wrap.setAttribute("aria-label", "Diagram (scroll sideways on small screens)");
      wrap.tabIndex = 0;
      el.parentNode.insertBefore(wrap, el);
      wrap.appendChild(el);
    });
  }

  /* Resolution timelines: tag each step with its stage name (the bold word
     that starts it) so escalations, containment and follow-ups get their own
     color. The stage word stays visible, so meaning never relies on color. */
  function tagTimelineStages() {
    document.querySelectorAll(".md-typeset .timeline > ol > li").forEach(function (li) {
      var label = li.querySelector("strong");
      if (!label || li.dataset.stage) return;
      li.dataset.stage = label.textContent.trim().toLowerCase().replace(/[^a-z]+/g, "-");
    });
  }

  /* Table filters: <div class="table-filters" data-columns="Priority,Status">
     builds toggle chips from the distinct values in those columns of the
     table(s) that follow it (data-scope="all" = every following table on the
     page). Rows are filtered client-side; selections in one group are OR-ed,
     different groups are AND-ed. Sections whose table ends up empty are
     hidden together with their heading. */
  function initTableFilters() {
    document.querySelectorAll(".md-typeset .table-filters").forEach(function (box, boxIndex) {
      if (box.dataset.ready) return;
      box.dataset.ready = "1";
      var columns = (box.dataset.columns || "").split(",").map(function (c) { return c.trim(); }).filter(Boolean);
      var tables = Array.prototype.filter.call(document.querySelectorAll(".md-typeset table"), function (t) {
        return box.compareDocumentPosition(t) & Node.DOCUMENT_POSITION_FOLLOWING;
      });
      if (box.dataset.scope !== "all") tables = tables.slice(0, 1);
      if (!tables.length || !columns.length) return;

      var rows = [];
      tables.forEach(function (table) {
        var headers = Array.prototype.map.call(table.querySelectorAll("thead th"), function (th) {
          return th.textContent.trim();
        });
        table.querySelectorAll("tbody tr").forEach(function (tr) {
          var values = {};
          columns.forEach(function (col) {
            var i = headers.indexOf(col);
            if (i >= 0 && tr.children[i]) values[col] = tr.children[i].textContent.trim();
          });
          rows.push({ tr: tr, table: table, values: values });
        });
      });

      var selected = {};
      var status = document.createElement("p");
      status.className = "table-filters__status";
      status.setAttribute("role", "status");
      status.setAttribute("aria-live", "polite");

      function apply() {
        var visible = 0;
        rows.forEach(function (row) {
          var show = columns.every(function (col) {
            var set = selected[col];
            return !set || !set.size || set.has(row.values[col]);
          });
          row.tr.hidden = !show;
          if (show) visible++;
        });
        tables.forEach(function (table) {
          var any = Array.prototype.some.call(table.querySelectorAll("tbody tr"), function (tr) { return !tr.hidden; });
          var section = table.closest(".kb-table") || table;
          section.hidden = !any;
          var heading = section.previousElementSibling;
          if (box.dataset.scope === "all" && heading && /^H[23]$/.test(heading.tagName)) heading.hidden = !any;
        });
        var filtering = columns.some(function (col) { return selected[col] && selected[col].size; });
        status.textContent = filtering ? "Showing " + visible + " of " + rows.length : rows.length + " items";
        clear.hidden = !filtering;
      }

      columns.forEach(function (col, colIndex) {
        var values = [];
        rows.forEach(function (row) {
          var v = row.values[col];
          if (v && values.indexOf(v) === -1) values.push(v);
        });
        values.sort(function (a, b) { return a.localeCompare(b, "en", { numeric: true }); });
        var group = document.createElement("div");
        group.className = "table-filters__group";
        group.setAttribute("role", "group");
        var labelId = "tf-" + boxIndex + "-" + colIndex;
        var label = document.createElement("span");
        label.className = "table-filters__label";
        label.id = labelId;
        label.textContent = col;
        group.setAttribute("aria-labelledby", labelId);
        group.appendChild(label);
        values.forEach(function (v) {
          var chip = document.createElement("button");
          chip.type = "button";
          chip.className = "table-filters__chip";
          chip.textContent = v;
          chip.setAttribute("aria-pressed", "false");
          chip.addEventListener("click", function () {
            var set = selected[col] || (selected[col] = new Set());
            if (set.has(v)) set.delete(v); else set.add(v);
            chip.setAttribute("aria-pressed", set.has(v) ? "true" : "false");
            apply();
          });
          group.appendChild(chip);
        });
        box.appendChild(group);
      });

      var clear = document.createElement("button");
      clear.type = "button";
      clear.className = "table-filters__clear";
      clear.textContent = "Clear filters";
      clear.addEventListener("click", function () {
        selected = {};
        box.querySelectorAll(".table-filters__chip").forEach(function (c) { c.setAttribute("aria-pressed", "false"); });
        apply();
      });
      var footer = document.createElement("div");
      footer.className = "table-filters__footer";
      footer.appendChild(status);
      footer.appendChild(clear);
      box.appendChild(footer);
      apply();
    });
  }

  function run() {
    wrapDiagrams();
    tagTimelineStages();
    initTableFilters();
    // Material renders Mermaid asynchronously and replaces the original
    // <pre class="mermaid"> with a new element, so wrap again when it appears.
    var content = document.querySelector(".md-content");
    if (content && "MutationObserver" in window) {
      var pending = false;
      new MutationObserver(function () {
        if (pending) return;
        pending = true;
        requestAnimationFrame(function () {
          pending = false;
          wrapDiagrams();
        });
      }).observe(content, { childList: true, subtree: true });
    }
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", run);
  else run();
})();
