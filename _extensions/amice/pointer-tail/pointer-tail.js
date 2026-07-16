var RevealPointerTail = window.RevealPointerTail || (function () {
  "use strict";

  var NAMED_KEYS = {
    backspace: 8,
    tab: 9,
    enter: 13,
    shift: 16,
    ctrl: 17,
    alt: 18,
    pausebreak: 19,
    capslock: 20,
    esc: 27,
    space: 32,
    pageup: 33,
    pagedown: 34,
    end: 35,
    home: 36,
    leftarrow: 37,
    uparrow: 38,
    rightarrow: 39,
    downarrow: 40,
    insert: 45,
    delete: 46
  };

  function clamp(value, min, max) {
    return Math.min(max, Math.max(min, value));
  }

  function normalizeKeyCode(key) {
    if (!key) {
      return 81;
    }

    var normalized = String(key).toLowerCase();
    if (normalized.length === 1) {
      return normalized.toUpperCase().charCodeAt(0);
    }

    return NAMED_KEYS[normalized] || 81;
  }

  function extend(target, source) {
    if (!source || typeof source !== "object") {
      return target;
    }

    Object.keys(source).forEach(function (key) {
      target[key] = source[key];
    });

    return target;
  }

  function resolveOptions(config) {
    var pointerTail = {};
    extend(pointerTail, config.pointerTail);
    extend(pointerTail, config["pointer-tail"]);
    extend(pointerTail, window.RevealPointerTailOptions);

    return {
      key: pointerTail.key || "q",
      keyCode: normalizeKeyCode(pointerTail.key || "q"),
      color: pointerTail.color || "var(--mit-red, red)",
      pointerSize: clamp(Number(pointerTail.pointerSize) || 12, 6, 48),
      trailLength: clamp(Number(pointerTail.trailLength) || 2, 2, 24),
      trailFalloff: clamp(Number(pointerTail.trailFalloff) || 0.65, 0.45, 0.95),
      trailTaper: clamp(Number(pointerTail.trailTaper) || 0.82, 0.2, 0.9),
      smoothing: clamp(Number(pointerTail.smoothing) || 0.38, 0.12, 0.75),
      headOpacity: clamp(Number(pointerTail.headOpacity) || 0.78, 0.25, 1),
      alwaysVisible: Boolean(pointerTail.alwaysVisible)
    };
  }

  return function () {
    var options = null;
    var overlay = null;
    var dots = [];
    var pointer = {
      x: window.innerWidth / 2,
      y: window.innerHeight / 2,
      seeded: false
    };
    var active = false;

    function seedDots() {
      for (var i = 0; i < dots.length; i += 1) {
        dots[i].x = pointer.x;
        dots[i].y = pointer.y;
      }
      pointer.seeded = true;
    }

    function setActive(nextActive) {
      active = nextActive;
      overlay.classList.toggle("is-active", active);
      document.body.classList.toggle("pointer-tail-hidden-cursor", active);
      if (active && !pointer.seeded) {
        seedDots();
      }
    }

    function toggleActive() {
      setActive(!active);
    }

    function handleMouseMove(event) {
      pointer.x = event.clientX;
      pointer.y = event.clientY;
      if (!pointer.seeded) {
        seedDots();
      }
    }

    function frame() {
      if (!pointer.seeded) {
        requestAnimationFrame(frame);
        return;
      }

      var leadX = pointer.x;
      var leadY = pointer.y;

      for (var i = 0; i < dots.length; i += 1) {
        var dot = dots[i];
        dot.x += (leadX - dot.x) * options.smoothing;
        dot.y += (leadY - dot.y) * options.smoothing;
        leadX = dot.x;
        leadY = dot.y;

        var progress = dots.length === 1 ? 0 : i / (dots.length - 1);
        var scale = 1 - progress * options.trailTaper;
        var opacity = active ? options.headOpacity * Math.pow(options.trailFalloff, i) : 0;

        dot.el.style.transform =
          "translate3d(" +
          dot.x.toFixed(2) +
          "px, " +
          dot.y.toFixed(2) +
          "px, 0) translate(-50%, -50%) scale(" +
          scale.toFixed(3) +
          ")";
        dot.el.style.opacity = opacity.toFixed(3);
      }

      requestAnimationFrame(frame);
    }

    function buildOverlay() {
      overlay = document.createElement("div");
      overlay.className = "reveal-pointer-tail-overlay";
      overlay.setAttribute("aria-hidden", "true");
      overlay.style.color = options.color;

      for (var i = 0; i < options.trailLength; i += 1) {
        var dotEl = document.createElement("div");
        dotEl.className = "reveal-pointer-tail-dot";
        dotEl.style.width = options.pointerSize + "px";
        dotEl.style.height = options.pointerSize + "px";
        overlay.appendChild(dotEl);
        dots.push({
          el: dotEl,
          x: pointer.x,
          y: pointer.y
        });
      }

      document.body.appendChild(overlay);
    }

    return {
      id: "pointer-tail",
      init: function (deck) {
        options = resolveOptions(deck.getConfig());
        buildOverlay();
        document.addEventListener("mousemove", handleMouseMove, { passive: true });
        deck.addKeyBinding({ keyCode: options.keyCode, key: options.key }, function () {
          toggleActive();
        });
        if (options.alwaysVisible) {
          setActive(true);
        }
        requestAnimationFrame(frame);
      }
    };
  };
})();
