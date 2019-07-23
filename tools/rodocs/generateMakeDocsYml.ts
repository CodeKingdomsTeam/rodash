import { basename } from 'path';

export function generateMakeDocsYml(files) {
	return `
site_name: Rodash Documentation
site_url: https://codekingdomsteam.github.io/rodash/
repo_name: CodeKingdomsTeam/rodash
repo_url: https://github.com/CodeKingdomsTeam/rodash

theme:
  name: material
  palette:
    primary: 'Grey'
    accent: 'Grey'

nav:
  - Home: index.md
  - Guide:
      - Arrays: guide/arrays.md
  - API Reference:
${files.map(name => `      - ${basename(name, '.md')}: api/${name}`).join('\n')}

extra_css:
  - rodocs.css

markdown_extensions:
  - admonition
  - codehilite:
      guess_lang: false
  - toc:
      permalink: true
  - pymdownx.superfences
`;
}
