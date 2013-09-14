# git-templates

GIT Templates for repositories

## Preparation

`gem i lazier mustache`

## Usage

`curl -s -L http://cow.tc/git-template-setup | ruby - [TEMPLATE] [[CONFIGURATION]]`

Where:

* `TEMPLATE`: Is the name of the template, like `ruby-gem`. See the branches of [https://github.com/ShogunPanda/git-templates](https://github.com/ShogunPanda/git-templates) for the full list of available branches: basically all but master.

* `CONFIGURATION`: A YAML file with values for the following variables:  
  * `name`: The name of the project.
  * `env`: The name of a env namespace. Default is uppercased version of `name`.
  * `module`: The main module of the project. Default is camelized version of `name`.
  * `year` (*current_year*): The current year for copyright notices. Default is the current year.
  * `author`: Author of the project. Default is **Shogun**.
  * `author_email`: Author's email. Default is **shogun@cowtech.it**.
  * `github_user`: GitHub username of the author. Default is **ShogunPanda**.
  * `summary`: Short description of the project.
  * `description`: Long description of the project. Defaults to `summary`.


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/ShogunPanda/git-templates/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

