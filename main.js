const fs = require("fs-extra");
const path = require("path");
const request = require("request-promise");
const requestErrors = require("request-promise/errors");

const STYLES = {
  indent: " ".repeat(2),
  reset: "\x1b[0m",
  bold: "\x1b[1m",
  normal: "\x1b[22m",
  black: "\x1b[30m",
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  cyan: "\x1b[34m",
  white: "\x1b[37m"
};

const titleize = function(subject){
  return subject.trim().replace(/[-_]/g, " ").replace(/(^|\s)(\w)/g, match => match.trim().toUpperCase());
};

const log = function(message){
  if(!process.env.NO_COLOR)
    message = message.replace(/@([a-z]+)@/g, (a, s) => STYLES[s] || "");

  console.log(message);
};

const fatal = function(message){
  message = `@red@\u{2717}@reset@ ${message}`;
  if(!process.env.NO_COLOR)
    message = message.replace(/@([a-z]+)@/g, (a, s) => STYLES[s] || "");

  console.error(message);
  process.exit(1); // eslint-disable-line no-process-exit
};

const compileTemplate = function(target, pattern, configuration){
  return target.replace(pattern, (_u1, _u2, key) => configuration[key] || "");
};

const apiCall = function(uri, configuration){
  return request({
    url: `https://api.github.com/repos/${configuration.repository}${uri}`,
    method: "GET",
    auth: configuration.authData,
    headers: {"User-Agent": `git-templates/${configuration._templateVersion}`},
    json: true
  })
    .catch(error => {
      if(!(error instanceof requestErrors.StatusCodeError))
        return fatal(`Cannot perform API call ${uri}: @red@[${error.constructor.name}] ${error.message}@reset@`);

      const body = typeof error.response.body === "object" ? error.response.body.message : error.response.body;
      return fatal(`API call returned an error ${uri}: @red@[HTTP ${error.response.statusCode}] ${body}@reset@`);
    });
};

const listTemplates = function(configuration, standalone = false){
  log(`@yellow@\u{22EF} Listing templates from @bold@@white@github.com/${configuration.repository}@normal@@yellow@ ...@reset@`);

  const matcher = new RegExp(`^${configuration.templatePrefix}([^/]+)$`);

  return apiCall("/git/trees/master?recursive=1", configuration)
    .then(results => {
      configuration.files = results.tree.reduce((accu, e) => {
        if(e.path.startsWith(configuration.templatePrefix))
          accu[e.path] = e.type === "tree" ? null : e.sha;
        return accu;
      }, {});

      const templates = Object.keys(configuration.files).filter(e => e.match(matcher)).map(t => t.replace(matcher, "$1"));

      if(!templates.length){
        log("@yellow@\u{2717} No valid templates found.@reset@");
        process.exit(1); // eslint-disable-line no-process-exit
      }

      if(standalone)
        log(`@green@\u{2713} Valid templates are:\n${templates.map(t => `@indent@@green@\u{00b7} @white@@bold@${t}@reset@`).join("\n")}`);
      return templates;
    });
};

const listLinters = function(configuration, standalone = false){
  if(standalone)
    log(`@yellow@\u{22EF} Listing linters from @bold@@white@github.com/${configuration.repository}@normal@@yellow@ ...@reset@`);

  const matcher = new RegExp(`^${configuration.lintersPrefix}([^/]+)$`);

  return apiCall("/git/trees/master?recursive=1", configuration)
    .then(results => {
      configuration.files = results.tree.reduce((accu, e) => {
        if(e.path.startsWith(configuration.lintersPrefix))
          accu[e.path] = e.sha;
        return accu;
      }, {});

      const linters = Object.keys(configuration.files).filter(e => e.match(matcher)).map(t => t.replace(matcher, "$1"));

      if(!linters.length){
        log("@yellow@\u{2717} No valid linters found.@reset@");
        process.exit(1); // eslint-disable-line no-process-exit
      }

      if(standalone)
        log(`@green@\u{2713} Valid linters are:\n${linters.map(t => `@indent@@green@\u{00b7} @white@@bold@${t}@reset@`).join("\n")}`);
      return linters;
    });
};

const sanitizeConfiguration = function(configuration){
  if(!configuration.description)
    configuration.description = configuration.summary;

  if(!this.url)
    configuration.url = `https://github.com/${configuration.githubUser}/${configuration.name}`;

  if(!this.docsUrl)
    configuration.docsUrl = `https://${configuration.githubUser.toLowerCase()}.github.io/${configuration.name}`;

  configuration.fileNameRegex = new RegExp(`(__(${Object.keys(configuration).join("|")})__)`, "gm");
  configuration.fileContentsRegex = new RegExp(`(\\{\\{(${Object.keys(configuration).join("|")})\\}\\})`, "gm");

  return configuration;
};

const parseConfiguration = function(configuration){
  // Parse and sanitize the config file
  configuration.configFile = path.resolve(configuration.configFile);

  // Merge configuration
  try{
    configuration = Object.assign(configuration, require(configuration.configFile)); // eslint-disable-line global-require
  }catch(e){
    if(!e.message.match(/^Cannot find module/)){
      log(`@yellow@\u{2717} Cannot load file @bold@${configuration.configFile}@normal@: @white@[${e.constructor.name}] ${e.message}@reset@`);
      log("@yellow@\u{2717} Will continue with default configuration.@reset@");
    }
  }

  return sanitizeConfiguration(configuration);
};

const validateTemplate = function(configuration){
  return listTemplates(configuration).then(templates => {
    if(templates.includes(configuration.template))
      return configuration;

    log(`@red@\u{2717} Invalid template @white@@bold@${configuration.template}@normal@@red@.@reset@`);
    return fatal(`@red@Valid templates are:\n${templates.map(t => `@indent@@red@\u{00b7} @white@@bold@${t}@reset@`).join("\n")}`);
  });
};

const showLinter = function(configuration){
  return listLinters(configuration).then(linters => {
    if(!linters.includes(configuration.template)){
      log(`@red@\u{2717} Invalid linter @white@@bold@${configuration.template}@normal@@red@.@reset@`);
      fatal(`@red@Valid linters are:\n${linters.map(t => `@indent@@red@\u{00b7} @white@@bold@${t}@reset@`).join("\n")}`);
    }

    const sha = configuration.files[`${configuration.lintersPrefix}${configuration.template}`];

    apiCall(`/git/blobs/${sha}`, configuration).then(result => {
      console.log(Buffer.from(result.content, "base64").toString("utf8"));
    });
  });
};

const createEntry = function(fullPath, content){
  fs.mkdirsSync(content ? path.dirname(fullPath) : fullPath); // eslint-disable-line no-sync

  // Write file content
  if(content)
    fs.writeFileSync(fullPath, content, {mode: 0o644}); // eslint-disable-line no-sync
};

const install = function(configuration){
  const prefix = `${configuration.templatePrefix}${configuration.template}`;
  log(`@yellow@\u{22EF} Downloading from @bold@@white@github.com/${configuration.repository}/${prefix}@normal@@yellow@ ...@reset@`);

  const files = Object.keys(configuration.files).filter(e => e.startsWith(prefix) && e !== prefix);

  // Download all files
  Promise.all(files.map(file => {
    const sha = configuration.files[file];

    if(!sha)
      return Promise.resolve(null);

    return apiCall(`/git/blobs/${sha}`, configuration)
      .then(result => {
        configuration.files[file] = Buffer.from(result.content, "base64").toString("utf8");
      });
  }))
    .then(() => {
      log(`@yellow@\u{22EF} ${configuration.dryRun ? "Will create" : "Created"} the following files and directories: @reset@`);

      // Create all files and folders
      for(let entry of files){ // eslint-disable-line prefer-const
        let relativePath = compileTemplate(entry.replace(prefix, "").slice(1), configuration.fileNameRegex, configuration);
        let content = configuration.files[entry];
        const usingTemplate = relativePath.endsWith(configuration.templateExtension);

        // Compile entry content
        if(content && usingTemplate){
          relativePath = relativePath.replace(configuration.templateExtension, "");
          content = compileTemplate(content, configuration.fileContentsRegex, configuration);
        }

        const fullPath = `${process.cwd()}/${relativePath}`;

        log(`@indent@@yellow@\u{00b7}@white@@bold@ ${relativePath} ${usingTemplate ? "@cyan@(using template compilation)@reset@" : ""}`);
        if(configuration.dryRun)
          continue;

        // Create the folder or the containing folder
        try{
          createEntry(fullPath, content);
        }catch(e){
          return Promise.reject([relativePath, content, e]);
        }
      }

      return true;
    })
    .catch(([relativePath, content, error]) => {
      fatal(`Cannot create ${content ? "file" : "directory"} @bold@${relativePath}@normal@: @red@[${error.constructor.name}] ${error.message}@reset@`);
    });
};

(function(){
  let configuration = {
    name: path.basename(process.cwd()),
    namespace: titleize(path.basename(process.cwd())),
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
    lintersPrefix: "linters/",
    templatePrefix: "templates/",
    templateExtension: ".gt-tpl",
    templateVersion: require(path.resolve(__dirname, "package.json")).version // eslint-disable-line global-require
  };

  if(process.env.GITHUB_AUTH){
    const tokens = process.env.GITHUB_AUTH.split(":");
    configuration.authData = {user: tokens[0], pass: tokens[1]};
  }

  // Parse command line
  for(let arg of process.argv.slice(2)){ // eslint-disable-line prefer-const
    if(arg.match(/^-[hu?]|--help|--usage$/)){
      console.log(
        `\u{2713} Usage: git-template ${path.basename(process.argv[1])} [-L|--linter] [-l|--list] [-n|--dry-run] TEMPLATE|LINTER [CONFIGURATION_FILE]`
      );
      process.exit(0); // eslint-disable-line no-process-exit
    }

    if(arg.match(/^-L|--linter$/))
      configuration.linterMode = true;
    else if(arg.match(/^-l|--list$/))
      configuration.listOnly = true;
    else if(arg.match(/^-n|--dry-run$/))
      configuration.dryRun = true;
    else if(!configuration.template)
      configuration.template = arg;
    else
      configuration.configFile = arg;
  }

  // Parse the configuration
  configuration = parseConfiguration(configuration);

  if(process.env.DEBUG){
    const formattedConfiguration = Object.keys(configuration)
      .map(k => `@indent@@yellow@\u{00b7}@white@@bold@ ${k}: @cyan@${configuration[k]}@reset@`).join("\n");
    log(`@yellow@\u{2713} Using the following configuration:\n${formattedConfiguration}`);
  }

  if(configuration.listOnly)
    return configuration.linterMode ? listLinters(configuration, true) : listTemplates(configuration, true);
  else if(!configuration.template) // The template is required
    fatal("Please provide the template. Run again with -h to have more informations.");
  else if(configuration.linterMode) // Download and install the template
    return showLinter(configuration);

  return validateTemplate(configuration).then(install);
})();
