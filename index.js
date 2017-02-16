#!/usr/bin/env node --harmony-async-await
const cli = require("commander");
const bluebird = require("bluebird");
const fs = bluebird.promisifyAll(require("fs-extra"));
const path = require("path");
const request = require("request-promise");
const requestErrors = require("request-promise/errors");
const emoji = require("node-emoji");
const chalkbars = require("chalkbars");

chalkbars.handlebars.registerHelper("emoji", emoji.get);

chalkbars.handlebars.registerHelper("list", (list, lastJoin = " or ", ...options) => {
  // Get the style
  const elementStyle = typeof options[0] === "string" ? options[0] : "highlight";

  // Apply style to all elements
  list = list.map(l => chalkbars.format(`{{#C ${elementStyle}}}${l}{{/C}}`));

  // Do the nice join
  if(list.length === 1)
    return list[0];

  const last = list.pop();
  return list.join(", ").concat(...[lastJoin, chalkbars.format(last)]);
});

chalkbars.handlebars.registerHelper("bulletedList", (list, indentation = "   ", ...options) => {
  // Get the style
  const elementStyle = typeof options[0] === "string" ? options[0] : null;

  if(typeof indentation !== "string")
    indentation = "   ";

  // Apply style to all elements
  list = list.map(l => chalkbars.format(`${indentation}• {{#C ${elementStyle}}}${l}{{/C}}`));

  return list.join("\n");
});

chalkbars.handlebars.registerHelper("progress", (current, total) => {
  const length = total.toString().length;
  current = (current + 1).toString();

  while(current.length < length)
    current = `0${current}`;

  return chalkbars.format("{{#C gray}}[{{current}}/{{total}}]{{/C}}", {current, total});
});

const GitTemplates = {
  info(message, ...args){
    chalkbars.log(`{{emoji "speech_balloon"}}  ${message}`, ...args);
  },

  warn(message, ...args){
    chalkbars.log(`{{emoji "warning"}}  ${message}`, ...args);
  },

  success(message, ...args){
    chalkbars.log(`{{emoji "beer"}}  ${message}`, ...args);
  },

  fatal(message, ...args){
    console.error(chalkbars.format(`{{emoji "x"}}  ${message}`, ...args));
    process.exit(1);
  },

  showUnexpectedError(error){
    const stackTraceRegex = /^at\s(.+)\s\((.+):(\d+):(\d+)\)$/;

    const stack = error.stack.trim().split("\n").slice(1).map(l => { // For each line in the stack trace but the first one
      const mo = l.trim().match(stackTraceRegex); // Match
      if(!mo) // Not a valid line
        return l;

      // Assign components
      let [, methodName, fileName, lineNumber, columnNumber] = mo;

      lineNumber = parseInt(lineNumber, 0);
      columnNumber = parseInt(columnNumber, 0);

      return `{{#C highlight}}${methodName}{{/C}} in {{#C warn}}${fileName}@${lineNumber}{{/C}}:${columnNumber}`;
    }).filter(s => s);

    // Show the error
    GitTemplates.fatal(
      "Unexpected error {{#C error}}{{type}}{{/C}} with message {{#C error}}{{{message}}}{{/C}}\n\n   Stack:\n{{{bulletedList stack}}}",
      {type: error.constructor.name, message: error.message, stack}
    );
  },

  titleize(subject){
    return subject.trim().replace(/[-_]/g, " ").replace(/(^|\s)(\w)/g, match => match.trim().toUpperCase());
  },

  compileTemplate(target, pattern, configuration){
    return target.replace(pattern, (_u, key) => configuration[key] || "");
  },

  loadDefaultConfiguration(){
    return {
      name: path.basename(process.cwd()),
      namespace: GitTemplates.titleize(path.basename(process.cwd())),
      env: path.basename(process.cwd()).toUpperCase().replace("-", "_"),
      year: new Date().getFullYear(),
      author: "Shogun",
      authorEmail: "shogun@cowtech.it",
      githubUser: "ShogunPanda",
      summary: "",
      authData: null,
      repository: "ShogunPanda/git-templates",
      description: null,
      configFile: ".git-template.json",
      templatePrefix: "templates/",
      templateExtension: ".gt-tpl",
      templateVersion: require(path.resolve(__dirname, "package.json")).version // eslint-disable-line global-require
    };
  },

  loadTemplateConfiguration(baseConfiguration){
    let configuration = baseConfiguration;

    // Try to parse the file
    try{
      configuration = Object.assign({}, baseConfiguration, require(path.resolve(baseConfiguration.configFile))); // eslint-disable-line global-require
    }catch(e){
      if(!e.message.match(/^Cannot find module/))
        GitTemplates.warn("Cannot load file {{#C highlight}}{{configFile}}{{/C}}. Will continue with default configuration.", baseConfiguration);
    }

    // Backfill some keys
    if(!configuration.description)
      configuration.description = configuration.summary;

    if(!configuration.url)
      configuration.url = `https://github.com/${configuration.githubUser}/${configuration.name}`;

    if(!configuration.docsUrl)
      configuration.docsUrl = `https://${configuration.githubUser.toLowerCase()}.github.io/${configuration.name}`;

    // Set expression for template compilation
    configuration.fileNameRegex = new RegExp(`(?:__(${Object.keys(configuration).join("|")})__)`, "gm");
    configuration.fileContentsRegex = new RegExp(`(?:\\{\\{(${Object.keys(configuration).join("|")})\\}\\})`, "gm");

    return configuration;
  },

  async apiCall(configuration, route){
    try{
      return await request({
        url: `https://api.github.com/repos/${configuration.repository}${route}`,
        method: "GET",
        auth: configuration.authData,
        headers: {"User-Agent": `git-templates/${configuration.templateVersion}`},
        json: true
      });
    }catch(error){
      if(!(error instanceof requestErrors.StatusCodeError))
        throw error;

      return GitTemplates.fatal(
        "GitHub API returned an error on call {{#C highlight}}{{{route}}}{{/C}}: {{#C error}}[HTTP {{status}}]{{/C}} {{#C highlight}}{{{body}}}{{/C}}",
        {route, status: error.response.statusCode, body: JSON.stringify(error.response.body)}
      );
    }
  },

  async listTemplates(configuration){
    // Get all entries
    const entries = await GitTemplates.apiCall(configuration, "/git/trees/master?recursive=1");
    const matcher = new RegExp(`^${configuration.templatePrefix}([^/]+)$`);

    // Find templates
    return entries.tree.map(e => { // eslint-disable-line arrow-body-style
      return e.type === "tree" && e.path.match(matcher) ? RegExp.$1 : null;
    }).filter(t => t);
  },

  async listTemplate(configuration, template){
    // Get all entries
    const entries = await GitTemplates.apiCall(configuration, "/git/trees/master?recursive=1");
    const matcher = new RegExp(`^${configuration.templatePrefix}${template}/(.+)`);

    // Find templates
    return entries.tree.reduce((accu, e) => { // eslint-disable-line arrow-body-style
      if(e.type !== "tree" && e.path.match(matcher))
        accu[RegExp.$1] = e.sha;

      return accu;
    }, {});
  },

  async install(configuration, [file, content], current, total){
    const relativePath = GitTemplates.compileTemplate(
      file.replace(new RegExp(`(?:${configuration.templateExtension})$`), ""), configuration.fileNameRegex, configuration
    );
    const fullPath = path.resolve(relativePath);

    const compile = file.endsWith(configuration.templateExtension);

    if(compile)
      content = GitTemplates.compileTemplate(content, configuration.fileContentsRegex, configuration);

    GitTemplates.info(
      "{{progress current total}} Creating file {{#C highlight}}{{relativePath}}{{/C}} {{#if compile}}{{#C warn}}(using template compilation) {{/C}}{{/if}}...",
      {relativePath, compile, current, total}
    );

    try{
      await fs.mkdirsAsync(path.dirname(fullPath));
      await fs.writeFileAsync(fullPath, content, {mode: 0o644});
    }catch(error){
      switch(error.code){
        case "EEXIST":
          GitTemplates.fatal("Cannot create one of the parent directories as it already exists as file.", {relativePath, compile});
          break;
        case "EISDIR":
          GitTemplates.fatal("Cannot create the file as the path already exists as directory.", {relativePath, compile});
          break;
        default:
          GitTemplates.fatal("Cannot create the file or parent directories: {{#C error}}[{{code}}]{{/C}} {{#C highlight}}{{{message}}}{{/C}}", error);
          break;
      }
    }
  },

  async actionList(configuration){
    GitTemplates.info("Listing templates from {{#C highlight}}github.com/{{repository}}{{/C}} ...", configuration);
    const templates = await GitTemplates.listTemplates(configuration);

    if(!templates.length)
      return GitTemplates.warn("No templates found.");

    return GitTemplates.success(
      'Found {{#C highlight}}{{templates.length}}{{/C}} template{{#if multiple}}s{{/if}}:\n{{{bulletedList templates "   " "highlight"}}}',
      {templates, multiple: templates.length > 1}
    );
  },

  async actionDownload(configuration, template){
    // Load the template configuration file, if present, and then sanitize it
    configuration = GitTemplates.loadTemplateConfiguration(configuration);

    const templates = await GitTemplates.listTemplates(configuration);

    // Validate template
    if(!templates.includes(template)){
      GitTemplates.fatal(
        'Invalid template {{#C highlight}}{{template}}{{/C}} requested. Valid templates are {{{list templates " or "}}}.',
        {template, templates: Object.keys(templates)}
      );
    }

    const entries = await GitTemplates.listTemplate(configuration, template);

    // Download all files in parallel
    GitTemplates.info(
      "Downloading template {{#C highlight}}{{template}}{{/C}} from {{#C highlight}}github.com/{{configuration.repository}}{{/C}} ...",
      {template, configuration}
    );

    await Promise.all(Object.entries(entries).map(async ([file, sha]) => {
      const result = await GitTemplates.apiCall(configuration, `/git/blobs/${sha}`);
      entries[file] = Buffer.from(result.content, "base64").toString("utf8");
    }));

    // Install files
    bluebird.each(Object.entries(entries), GitTemplates.install.bind(null, configuration));
  },

  async main(){
    const configuration = GitTemplates.loadDefaultConfiguration();

    try{
      cli.debug = (process.env.NODE_DEBUG || "").includes("git-templates");
      cli.usage("[options] <template>");
      cli.option("-l, --list", "Only list templates.");
      cli.option("-n, --dry-run", "Only show action but do not run them.");
      cli.option("-a, --auth <AUTH>", "GitHub authentication string to use to avoid rate-limit. It must be in the form $USER:[$PASSWORD|$TOKEN]");
      cli.parse(process.argv);

      const template = cli.args[0];

      if(cli.auth){
        const [username, password] = cli.auth.split(":");
        configuration.authData = {username, password};
      }

      if(cli.list)
        await GitTemplates.actionList(configuration);
      else if(template)
        await GitTemplates.actionDownload(configuration, template);
      else
        GitTemplates.fatal("Please specify a template name or use {{#C highlight}}-l|--list{{/C}} to list them.");
    }catch(e){
      GitTemplates.showUnexpectedError(e);
    }
  }
};

GitTemplates.main();
