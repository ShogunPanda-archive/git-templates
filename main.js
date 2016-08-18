"use strict";

const fs = require("fs");
const path = require("path");
const childProcess = require("child_process");
const https = require("https");
const urlParser = require("url");

const HTTP_STATUS_OK = 200;

if(typeof String.prototype.titleize !== "function"){
  String.prototype.titleize = function(){
    return this.trim().replace(/[-_]/g, " ").replace(/(^|\s)(\w)/g, match => match.trim().toUpperCase());
  };
}

if(typeof String.prototype.padRight !== "function"){
  String.prototype.padRight = function(length, filler){
    if(length < 0)
      throw new RangeError("Invalid length.");

    return this.length >= length ? this : (filler.repeat(length) + this).slice(-length);
  };
}

class GitTemplatesInstaller{
  run(){
    this.apiRoot = `https://${process.env.GITHUB_AUTH ? `${process.env.GITHUB_AUTH}@` : ""}api.github.com/repos`;
    this.configuration = GitTemplatesInstaller.defaultConfiguration;
    this.template = null;
    this.configFile = null;
    this.listOnly = false;
    this.dryRun = false;

    // Parse the command line
    process.argv.slice(2).forEach(arg => {
      if(arg.match(/^-[hu\?]|--help|--usage$/)){
        console.log(`node ${path.basename(process.argv[1])} [-l|--list] [-n|--dry-run] TEMPLATE [CONFIGURATION_FILE]`);
        process.exit(0);
      }

      if(arg.match(/^-l|--list$/))
        this.listOnly = true;
      else if(arg.match(/^-n|--dry-run$/))
        this.dryRun = true;
      else if(!this.template)
        this.template = arg;
      else if(!this.configFile)
        this.configFile = arg;
    });

    if(this.listOnly)
      return this.list();

    // Parse and sanitize the config file
    if(!this.configFile)
      this.configFile = "./.git-template.json";
    this.configFile = path.resolve(this.configFile);

    // Merge configuration
    try{
      Object.assign(this.configuration, require(this.configFile));
    }catch(e){
      console.error(`[ WARN] Cannot load file ${this.configFile}, will continue with default configuration.`);
    }

    this.sanitizeConfiguration();

    // The template is required
    if(!this.template)
      this._showError("Please provide the template. Run again with -h to have more informations.");

    // Only perform on empty directories
    if(!this.verifyEmptyDirectory())
      this._showError("This utility can only be used on empty directories (configuration file are ignored)");

    return this.validateTemplate(sha => this.perform(sha));
  }

  sanitizeConfiguration(){
    if(!this.configuration.description)
      this.configuration.description = this.configuration.summary;

    if(!this.url)
      this.configuration.url = `https://github.com/${this.configuration.githubUser}/${this.configuration.name}`;
    
    if(!this.docsUrl)
      this.configuration.docsUrl = `https://${this.configuration.githubUser.toLowerCase()}.github.io/${this.configuration.name}`;

    this.fileNameRegex = new RegExp(`(__(${Object.keys(this.configuration).join("|")})__)`, "gm");
    this.fileContentsRegex = new RegExp(`(\\{\\{(${Object.keys(this.configuration).join("|")})\\}\\})`, "gm");
  }

  showConfiguration(){
    console.log(`[ INFO] Using the following configuration:`);

    Object.keys(this.configuration).forEach(k => {
      console.log(`${GitTemplatesInstaller.indentation}* ${k}: ${this.configuration[k]}`);
    });
  }

  validateTemplate(callback){
    this._listTemplates(templates => {
      const valid = templates.find(t => t.path === this.template);

      if(!valid)
        return this._showError(`Template "${this.template}" is not valid. Run again with -l to list valid templates.`);

      callback(valid.sha);
    });
  }

  verifyEmptyDirectory(){
    return !fs.readdirSync(process.cwd()).map(p => path.resolve(p)).filter(p => p !== this.configFile).length;
  }

  perform(sha){
    this.showConfiguration();

    // Get all the files
    this._apiCall(
      `${this.apiRoot}/${GitTemplatesInstaller.repository}/git/trees/${sha}?recursive=1`,
      "Listing template contents",
      "Cannot list template contents",
      (rootStatus, rootHeaders, rootBody) => {
        // Construct a list of [path, URL]
        const contents = JSON.parse(rootBody).tree.reduce((accu, object) => {
          if(object.type !== "tree")
            accu.push([object.path, object.url]);
          return accu;
        }, []);

        // Start setting up files
        this.setupFile(contents, 1, contents.length, contents.length.toString().length);
      }
    );
  }

  list(){
    this._listTemplates(templates => {
      templates = templates.map(t => t.path);

      if(!templates.length)
        console.log(`[ WARN] No valid templates found.`);
      else
        console.log(`[ INFO] Valid templates are:\n${templates.map(p => `${GitTemplatesInstaller.indentation}* ${p}`).join("\n")}`);
    });
  }

  setupFile(files, index, total, indexPadding){
    const currentFile = files.shift();
    const progress = `[${index.toString().padRight(indexPadding, "0")}/${total}]`;
    const padder = " ".repeat(progress.length);
    let destination = currentFile[0];
    let template = false;
    let url = currentFile[1];

    // Check if template is needed
    if(destination.endsWith(".gt-tpl")){
      template = true;
      destination = destination.replace(/.gt-tpl$/, "");
    }

    // Download the file
    if(process.env.GITHUB_AUTH)
      url = url.replace("https://", `https://${process.env.GITHUB_AUTH}@`);

    console.log(`[ INFO] ${progress} Creating file ${destination}${template ? " (with template compilation)" : ""} ...`);

    this._apiCall(
      url,
      `${padder} * Downloading ${url} ...`, "Cannot download file",
      (status, headers, body) => {
        this.createFile(destination, new Buffer(JSON.parse(body).content, "base64").toString("utf8"), template, () =>{
          if(files.length)
            this.setupFile(files, index + 1, total, indexPadding);
        });
      }
    );
  }

  createFile(destination, contents, template, callback){
    destination = path.resolve(this._compileTemplate(destination, this.fileNameRegex));
    const parent = path.dirname(destination);

    if(template)
      contents = this._compileTemplate(contents, this.fileContentsRegex);

    childProcess.exec(`mkdir -p ${parent}`, mkdirError => {
      if(mkdirError)
        return this._showError(`Cannot create directory "${parent}": ${mkdirError}`);

      return fs.writeFile(destination, contents, writeError => {
        if(writeError)
          return this._showError(`Cannot create file "${destination}": ${writeError}`);

        return callback();
      });
    });
  }

  _showError(error){
    console.error(`[FATAL] ${error}`);
    process.exit(-1);
  }

  _apiCall(url, info, errorPrefix, callback){
    const options = urlParser.parse(url);
    options.headers = {"User-Agent": "git-templates/1.0.0"};

    console.log(`[ INFO] ${info} ...`);
    // Perform the GH call
    https
      .get(options, (res) => {
        let buffer = new Buffer(0);

        res
        // Concat data
          .on("data", data => {
            buffer = Buffer.concat([buffer, data]);
          })
          // Call the callback
          .on("end", () => {
            if(res.statusCode !== HTTP_STATUS_OK)
              return this._showError(`${errorPrefix} (HTTP ${res.statusCode}): ${buffer.toString()}`);

            return callback(res.statusCode, res.headers, buffer.toString());
          });
      })
      .on("error", e => {
        this._showError(`Cannot perform HTTP call to ${url}: ${e.message}`);
      });
  }

  _listTemplates(callback){
    // First of all, find the SHA of the templates folder
    this._apiCall(
      `${this.apiRoot}/${GitTemplatesInstaller.repository}/git/trees/master`,
      `Accessing repository ${GitTemplatesInstaller.repository}`,
      "Cannot access repository",
      (rootStatus, rootHeaders, rootBody) => {
        // Find the right item
        const root = JSON.parse(rootBody).tree.find(p => p.type === "tree" && p.path === "templates");

        if(!root)
          return callback([]);

        // Now list the templates folder
        return this._apiCall(
          `${this.apiRoot}/${GitTemplatesInstaller.repository}/git/trees/${root.sha}`,
          "Fetching available templates",
          "Cannot list templates",
          (status, headers, body) => {
            if(status !== HTTP_STATUS_OK)
              this._showError(` (HTTP ${status}): ${rootBody.toString()}`);

            callback(JSON.parse(body).tree.filter(p => p.type !== "blob"));
          }
        );
      });
  }

  _compileTemplate(target, pattern){
    return target.replace(pattern, (_u1, _u2, key) => this.configuration[key] || "");
  }
}

GitTemplatesInstaller.indentation = " ".repeat(8);
GitTemplatesInstaller.repository = "ShogunPanda/git-templates";

GitTemplatesInstaller.defaultConfiguration = {
  name: path.basename(process.cwd()),
  namespace: path.basename(process.cwd()).titleize(),
  env: path.basename(process.cwd()).toUpperCase().replace("-", "_"),
  year: new Date().getFullYear(),
  author: "Shogun",
  authorEmail: "shogun@cowtech.it",
  githubUser: "ShogunPanda",
  summary: "",
  description: null
};

const main = new GitTemplatesInstaller();
main.run();
