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
    accent: 'Blue'

nav:
  - Home: index.md
  - Getting Started: getting-started.md
  - API Reference:
${files.map(name => `      - ${basename(name, '.md')}: api/${name}`).join('\n')}
  - Types: types.md
  - Glossary: glossary.md

extra_css:
  - docublox.css

markdown_extensions:
  - admonition
  - codehilite:
      guess_lang: false
  - toc:
      permalink: true
  - pymdownx.superfences
`;
}
