import Ember from "ember";
import config from "./config/environment";

const Router = Ember.Router.extend({
  location: config.locationType,
  rootURL: config.rootURL
});

Router.map(function(){ // eslint-disable-line prefer-arrow-callback, array-callback-return

});

export default Router;
