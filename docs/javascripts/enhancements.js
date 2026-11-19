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

  function run() {
    wrapDiagrams();
    tagTimelineStages();
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
