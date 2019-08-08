module.exports = {
	useTabs: true,
	printWidth: 100,
	singleQuote: true,
	trailingComma: 'all',
	overrides: [
		{
			files: '*.html',
			options: {
				trailingComma: 'none',
			},
		},
	],
};
