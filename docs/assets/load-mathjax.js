window.MathJax = {
	tex: {
		// Override default maths environment delimiters (completely remove)
		// See https://docs.mathjax.org/en/latest/options/input/tex.html#tex-options
		inlineMath: [],
		displayMath: [],
		processEnvironments: false,
		processRefs: false,
	},
	svg: {
		fontCache: 'global'
	},
	output: {
		font: 'mathjax-fira'
	},
	// Completely override default maths search routine
	// Maths shall be placed in <tex>inline maths</tex> and <dtex>display maths</dtex>
	// Taken directly from
	// https://docs.mathjax.org/en/latest/advanced/synchronize/renderactions.html#a-render-action-to-use-tags-for-math-delimiters
	options: {
		renderActions: {
			find: [10,
				(doc) => {
					for (const node of document.querySelectorAll('tex, dtex')) {
						if (node.childNodes.length !== 1 || node.firstChild.nodeName !== '#text') continue;
						const display = node.nodeName.toLowerCase() === 'dtex';
						const math = new doc.options.MathItem(node.textContent, doc.inputJax.tex, display);
						const text = document.createTextNode('');
						node.parentNode.replaceChild(text, node);
						math.start = {node: text, delim: '', n: 0};
						math.end = {node: text, delim: '', n: 0};
						doc.math.push(math);
					}
				},
				'',
				false
			]
		}
	}
};

// Single script config and load method
// Taken directly from
// https://docs.mathjax.org/en/latest/web/configuration.html
(function () {
	var script = document.createElement('script');
	script.src = 'https://cdn.jsdelivr.net/npm/mathjax@4/tex-svg.js';
	script.defer = true;
	document.head.appendChild(script);
})();
