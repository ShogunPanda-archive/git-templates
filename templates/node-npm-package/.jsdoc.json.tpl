{
  "source": {
    "include": ["main.js", "lib"]
  },
  "plugins": ["plugins/markdown"],
  "opts": {
    "encoding": "utf8",
    "destination": "./docs/",
    "recurse": true,
    "readme": "README.md"
  },
  "templates": {
    "systemName": "{{name}}",
    "copyright": "{{year}} and above {{author}} <{{authorEmail}}>",
    "includeDate": false,
    "navType": "vertical",
    "theme": "sandstone",
    "linenums": true,
    "collapseSymbols": false,
    "inverseNav": true,
    "syntaxTheme": "dark",
    "sort": false
  }
}
