/* eslint-env commonjs */

const EmberApp = require("ember-cli/lib/broccoli/ember-app");

module.exports = function(defaults){
  const deploying = (/^(production|staging)/).test(EmberApp.env());

  const app = new EmberApp(defaults, {
    tests: false,
    sassOptions: {
      includePaths: [],
      extension: "sass"
    },
    minifyJS: {enabled: deploying},
    minifyCSS: {enabled: deploying},
    gzip: {enabled: deploying, keepUncompressed: true, extensions: ["js", "css", "jpg", "png", "bmp", "svg", "eot", "otf", "ttf", "woff", "woff2"]}
  });

  // Utility libraries
  [].forEach(e => app.import(e));

  return app.toTree();
};
