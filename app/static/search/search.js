(function () {
  var form = document.getElementById("search-form");
  var input = document.getElementById("search-query");
  var status = document.getElementById("status");
  var profileStatus = document.getElementById("profile-status");
  var results = document.getElementById("results");
  var latestSearchId = 0;

  function escapeHtml(value) {
    return String(value || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function loginRedirect() {
    var target = window.location.pathname + window.location.search;
    window.location.href =
      "/accounts/login/?next=" + encodeURIComponent(target || "/search");
  }

  function setStatus(message) {
    status.textContent = message || "";
  }

  function errorMessage(code, fallback) {
    var messages = {
      paperless_api_error: "Paperless is unavailable right now.",
      search_failed: "Search failed. Try again in a moment.",
      not_authenticated: "Your Paperless session expired.",
      "q is required": "Enter a search query.",
    };
    return messages[code] || fallback || "Something went wrong.";
  }

  function parseJsonResponse(response, fallback) {
    var contentType = response.headers.get("content-type") || "";
    if (contentType.indexOf("application/json") === -1) {
      throw new Error(fallback);
    }
    return response.json().catch(function () {
      throw new Error(fallback);
    });
  }

  function renderEmpty(message) {
    results.innerHTML =
      '<div class="empty-state">' + escapeHtml(message) + "</div>";
  }

  function meta(label, value) {
    if (value === null || value === undefined || value === "") {
      return "";
    }
    return "<span>" + escapeHtml(label + ": " + value) + "</span>";
  }

  function resultCard(result) {
    var title = result.title || "Document " + result.id;
    var source =
      Array.isArray(result.sources) && result.sources.length
        ? result.sources.join(" + ")
        : "search";
    var snippet = result.matched_chunk || "";
    var pageCount = result.page_count
      ? result.page_count + (result.page_count === 1 ? " page" : " pages")
      : "";

    return [
      '<article class="result-card">',
      "<div>",
      '<a class="result-title" href="' +
        escapeHtml(result.document_url) +
        '">' +
        escapeHtml(title) +
        "</a>",
      snippet ? '<p class="snippet">' + escapeHtml(snippet) + "</p>" : "",
      '<div class="meta">',
      meta("Created", result.created),
      meta("Source", source),
      meta("Score", result.relevance_score),
      pageCount ? "<span>" + escapeHtml(pageCount) + "</span>" : "",
      "</div>",
      "</div>",
      '<a class="open-link" href="' +
        escapeHtml(result.document_url) +
        '" aria-label="' +
        escapeHtml("Open " + title + " in Paperless") +
        '">Open in Paperless</a>',
      "</article>",
    ].join("");
  }

  function renderResults(payload) {
    if (!payload.results || payload.results.length === 0) {
      renderEmpty("No matching documents found.");
      setStatus("No results");
      return;
    }

    results.innerHTML = payload.results.map(resultCard).join("");
    setStatus(
      payload.count +
        (payload.count === 1 ? " result" : " results") +
        ' for "' +
        payload.query +
        '"',
    );
  }

  function runSearch(query) {
    latestSearchId += 1;
    var searchId = latestSearchId;
    var trimmed = query.trim();
    if (!trimmed) {
      input.focus();
      setStatus("Enter a search query.");
      results.innerHTML = "";
      return;
    }

    setStatus("Searching...");
    results.innerHTML = "";
    fetch(
      "/search/api/documents?q=" + encodeURIComponent(trimmed) + "&limit=10",
      {
        headers: { Accept: "application/json" },
      },
    )
      .then(function (response) {
        if (searchId !== latestSearchId) {
          return null;
        }
        if (response.status === 401) {
          loginRedirect();
          return null;
        }
        return parseJsonResponse(response, "Search failed").then(
          function (body) {
            if (!response.ok) {
              throw new Error(errorMessage(body.error, "Search failed"));
            }
            return body;
          },
        );
      })
      .then(function (payload) {
        if (searchId !== latestSearchId) {
          return;
        }
        if (payload) {
          renderResults(payload);
          window.history.replaceState(
            null,
            "",
            "/search?q=" + encodeURIComponent(trimmed),
          );
        }
      })
      .catch(function (error) {
        if (searchId !== latestSearchId) {
          return;
        }
        setStatus(error.message || "Search failed");
        renderEmpty("Search is unavailable right now.");
      });
  }

  fetch("/search/api/me", { headers: { Accept: "application/json" } })
    .then(function (response) {
      if (response.status === 401) {
        loginRedirect();
        return null;
      }
      return parseJsonResponse(response, "Profile unavailable").then(
        function (body) {
          if (!response.ok) {
            throw new Error(errorMessage(body.error, "Profile unavailable"));
          }
          return body;
        },
      );
    })
    .then(function (payload) {
      if (!payload) {
        return;
      }
      var profile = payload.profile || {};
      var name =
        [profile.first_name, profile.last_name].filter(Boolean).join(" ") ||
        profile.email ||
        profile.username ||
        "Paperless";
      profileStatus.textContent = "Signed in as " + name;
    })
    .catch(function () {
      profileStatus.textContent = "Sign-in status unavailable";
    });

  form.addEventListener("submit", function (event) {
    event.preventDefault();
    runSearch(input.value);
  });

  var params = new URLSearchParams(window.location.search);
  var initialQuery = params.get("q");
  if (initialQuery) {
    input.value = initialQuery;
    runSearch(initialQuery);
  } else {
    input.focus();
  }
})();
