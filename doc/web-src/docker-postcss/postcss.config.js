const postcssPresetEnv = require('postcss-preset-env');

module.exports = {
	plugins: [
		postcssPresetEnv({
			stage: 3,
			browsers: [
				'last 4 versions',
				'iOS >= 16',
				'Safari >= 13.1',
				'Chrome >= 80',
				'Firefox >= 74',
				'Edge >= 80'
			],
			features: {
				'nesting-rules': true
			},
			autoprefixer: true
		})
	]
};
