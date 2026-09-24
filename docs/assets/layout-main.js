//****************************************************************
// Menu
//********************************
class MenuController {
	constructor() {
		this.rootElement = document.getElementById("js-header");
		this.buttonElementDesktop = document.getElementById("js-aside-switch");
		this.buttonElement = document.getElementById("js-header-switch");
		this.imgOpenElement = document.getElementById("js-header-img-open");
		this.imgCloseElement = document.getElementById("js-header-img-close");
		this.asideElement = document.getElementById("js-aside");
		this.navElement = document.getElementById("js-nav");
		this.timer = null;
		this.isPinned = (localStorage.getItem("CDS-sidebarPinned") ?? "true") === "true";

		// Must match the value of --size-tablet in app.css
		this.isMobileQuery ="(max-width: 900px)";

		// Initialise
		// SEE ALSO: Snippet inlined into layoutMain.html
		const isMobile = window.matchMedia(this.isMobileQuery).matches;
		if(isMobile) {
			this.CloseMenu();
		}
		else if(this.isPinned) {
			this.OpenMenu();
			this.buttonElementDesktop.classList.add("pinned");
		}
		else {
			this.CloseMenu();
			this.buttonElementDesktop.classList.remove("pinned");
		}

		if(isMobile) {
			// pageshow includes detection of the browser back button, in which state the menu would be open
			window.addEventListener("pageshow", this.CloseMenu.bind(this));
		}
		this.buttonElement.addEventListener("click", this.ToggleMenu.bind(this));
		this.buttonElementDesktop.addEventListener("click", this.TogglePinned.bind(this));
		this.asideElement.addEventListener("mouseenter", this.HoverIn.bind(this));
		this.asideElement.addEventListener("mouseleave", this.HoverOut.bind(this));
	}

	IsOpen() {
		return !!this.navElement.classList.contains("open");
	}

	OpenMenu() {
		this.imgOpenElement.classList.add("hidden");
		this.imgCloseElement.classList.remove("hidden");
		this.buttonElementDesktop.classList.add("open");
		this.asideElement.classList.add("open");
		this.navElement.classList.add("open");
		this.buttonElement.setAttribute("aria-expanded", "true");
		this.buttonElementDesktop.setAttribute("aria-expanded", "true");
	}

	CloseMenu() {
		this.imgOpenElement.classList.remove("hidden");
		this.imgCloseElement.classList.add("hidden");
		this.buttonElementDesktop.classList.remove("open");
		this.asideElement.classList.remove("open");
		this.navElement.classList.remove("open");
		this.buttonElement.setAttribute("aria-expanded", "false");
		this.buttonElementDesktop.setAttribute("aria-expanded", "false");
	}

	ToggleMenu(event) {
		if(this.IsOpen()) { this.CloseMenu(); }
		else              { this.OpenMenu(); }
		if(event) { event.preventDefault(); }
	}

	TogglePinned() {
		this.isPinned = !this.isPinned;
		this.buttonElementDesktop.classList.toggle("pinned");
		localStorage.setItem("CDS-sidebarPinned", this.isPinned);
		if(this.isPinned) { this.OpenMenu(); }
		else              { this.CloseMenu(); }
	}

	HoverIn() {
		clearTimeout(this.timer);
		const isMobile = window.matchMedia(this.isMobileQuery).matches;
		if(isMobile) { return; }
		this.OpenMenu();
	}

	HoverOut() {
		clearTimeout(this.timer);
		const isMobile = window.matchMedia(this.isMobileQuery).matches;
		if(isMobile) { return; }
		if(this.isPinned) { return; }
		this.timer = setTimeout(this.CloseMenu.bind(this), 200);
	}
}

new MenuController();


//****************************************************************
// Contrast toggle
//********************************
class ContrastToggle {
	constructor() {
		this.rootElement = document.getElementById("js-contrast-toggle");
		this.bodyElement = document.querySelector("body");
		this.isOn = (localStorage.getItem("CDS-highContrast") ?? "true") === "true";

		// Initialise
		if(this.isOn) { this.TurnOn(); }
		else          { this.TurnOff(); }

		this.rootElement.addEventListener("click", this.Toggle.bind(this));
	}

	TurnOn() {
		this.isOn = true;
		this.rootElement.classList.add("enabled");
		this.bodyElement.classList.add("high-contrast");
		this.rootElement.setAttribute("aria-pressed", "true");
		this.rootElement.textContent = "Dim Screen";
	}

	TurnOff() {
		this.isOn = false;
		this.rootElement.classList.remove("enabled");
		this.bodyElement.classList.remove("high-contrast");
		this.rootElement.setAttribute("aria-pressed", "false");
		this.rootElement.textContent = "High Contrast";
	}

	Toggle() {
		if(this.isOn) { this.TurnOff(); }
		else          { this.TurnOn(); }
		localStorage.setItem("CDS-highContrast", this.isOn);
	}
}

new ContrastToggle();


//****************************************************************
// Links to current page
//********************************
const urlCurrentPageStr = window.location.origin + window.location.pathname
Array.from(document.querySelectorAll('a')).forEach(el => {
	try {
		const urlLink = new URL(el.href);
		const urlLinkStr = urlLink.origin + urlLink.pathname;
		if(urlLinkStr === urlCurrentPageStr) {
			el.classList.add('current-page');
			el.setAttribute('aria-current', 'page');
		}
	}
	catch {
		// fallthrough
	}
});


//****************************************************************
// Tables
//********************************
// Snap sizes to largest set increment
class TableSnapSize {
	constructor() {
		this.containerElement = document.querySelector('.container-inner');
		this.tableElements = this.containerElement.querySelectorAll('.ref-summary-args');
		this.snapSizes = [0.2, 0.25, 0.5, 0.75, 0.8, 0.9];
		this.rafPending = false;
		this.normalisedColumnWidths_atMaxContent = new Map();
		this.headRowElements = new Map();
		this.normalisedMaxWidthCol0 = 0
		this.normalisedMaxWidthCol1 = 0
		this.normalisedMaxWidthCol2 = 0

		if(this.tableElements.length === 0) { return; }

		// Measure table widths
		// Normalise by current font size
		const currentFontSize = parseFloat( getComputedStyle(this.tableElements[0]).fontSize );
		for(const tb of this.tableElements) {
			tb.style.width = "max-content";
			const rows = tb.querySelectorAll('thead > tr:last-child > th');
			this.headRowElements.set(tb, rows);
			this.normalisedColumnWidths_atMaxContent.set(tb,[
				rows[0].offsetWidth / currentFontSize,
				rows[1].offsetWidth / currentFontSize,
				rows[2].offsetWidth / currentFontSize
			]);
			this.normalisedMaxWidthCol0 = Math.max(this.normalisedMaxWidthCol0, rows[0].offsetWidth / currentFontSize);
			this.normalisedMaxWidthCol1 = Math.max(this.normalisedMaxWidthCol1, rows[1].offsetWidth / currentFontSize);
			this.normalisedMaxWidthCol2 = Math.max(this.normalisedMaxWidthCol2, rows[2].offsetWidth / currentFontSize);
			tb.style.width = '';
		}

		// Using requestAnimationFrame to limit the drawing rate
		const observer = new ResizeObserver(() => {
			if(this.rafPending) { return };
			this.rafPending = true;
			requestAnimationFrame(() => {
				this.rafPending = false;
				this.SnapSize();
			});
		});
		observer.observe(this.containerElement);
		this.SnapSize();
	}

	SnapSize() {
		const currentFontSize = parseFloat( getComputedStyle(this.tableElements[0]).fontSize );

		for(const tb of this.tableElements) {
			const rows = this.headRowElements.get(tb);
			const normalisedWidths = this.normalisedColumnWidths_atMaxContent.get(tb)

			// Force all col0 same width
			rows[0].style.width    = `${this.normalisedMaxWidthCol0 * currentFontSize}px`;
			rows[0].style.minWidth = `${this.normalisedMaxWidthCol0 * currentFontSize}px`;
			rows[0].style.maxWidth = `${this.normalisedMaxWidthCol0 * currentFontSize}px`;

			// Snap cols 1 and 2
			// Add padding of 1*fontsize (this is 2ex (1ex on either side), same as in the css file)
			const ratio1 = normalisedWidths[1] / (this.normalisedMaxWidthCol1)
			const ratio2 = normalisedWidths[2] / (this.normalisedMaxWidthCol2)
			let snappedRatio1 = 1;
			let snappedRatio2 = 1;
			for(const s of this.snapSizes) { if(ratio1<=s) { snappedRatio1=s; break; } }
			for(const s of this.snapSizes) { if(ratio2<=s) { snappedRatio2=s; break; } }
			rows[1].style.width    = `${(snappedRatio1 * this.normalisedMaxWidthCol1 + 1) * currentFontSize}px`;
			rows[1].style.minWidth = `${(snappedRatio1 * this.normalisedMaxWidthCol1 + 1) * currentFontSize}px`;
			rows[1].style.maxWidth = `${(snappedRatio1 * this.normalisedMaxWidthCol1 + 1) * currentFontSize}px`;
			rows[2].style.width    = `${(snappedRatio2 * this.normalisedMaxWidthCol2 + 1) * currentFontSize}px`;
			rows[2].style.minWidth = `${(snappedRatio2 * this.normalisedMaxWidthCol2 + 1) * currentFontSize}px`;
			rows[2].style.maxWidth = `${(snappedRatio2 * this.normalisedMaxWidthCol2 + 1) * currentFontSize}px`;
		}
	}
}

new TableSnapSize();


