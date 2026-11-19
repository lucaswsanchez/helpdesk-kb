/*
 * Responsive data tables.
 *
 * Copies each column header into a data-label attribute on its cells and marks
 * wide tables with data-stack. On small screens extra.css then renders every
 * row as a labelled card instead of forcing horizontal scrolling. Tables with
 * two columns (already narrow), the priority matrix (a grid that must stay a
 * grid) and compact overview tables (which drop minor columns instead) are
 * left as they are.
 */
(function () {
  "use strict";

  function prepare(table) {
    if (table.dataset.stack !== undefined || table.closest(".matrix-table, .compact-table")) return;
    var headers = Array.prototype.map.call(table.querySelectorAll("thead th"), function (th) {
      return th.textContent.trim();
    });
    if (headers.length < 3) return;
    table.dataset.stack = "";
    table.querySelectorAll("tbody tr").forEach(function (tr) {
      Array.prototype.forEach.call(tr.children, function (td, i) {
        if (headers[i]) td.setAttribute("data-label", headers[i]);
      });
    });
  }

  function run() {
    document.querySelectorAll(".md-typeset table:not([class])").forEach(prepare);
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", run);
  else run();
})();
