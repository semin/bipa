var Prototype={Version:"1.6.0",Browser:{IE:!!(window.attachEvent&&!window.opera),Opera:!!window.opera,WebKit:navigator.userAgent.indexOf("AppleWebKit/")>-1,Gecko:navigator.userAgent.indexOf("Gecko")>-1&&navigator.userAgent.indexOf("KHTML")==-1,MobileSafari:!!navigator.userAgent.match(/Apple.*Mobile.*Safari/)},BrowserFeatures:{XPath:!!document.evaluate,ElementExtensions:!!window.HTMLElement,SpecificElementExtensions:document.createElement("div").__proto__&&document.createElement("div").__proto__!==document.createElement("form").__proto__},ScriptFragment:"<script[^>]*>([\\S\\s]*?)<\/script>",JSONFilter:/^\/\*-secure-([\s\S]*)\*\/\s*$/,emptyFunction:function(){},K:function(A){return A;}};if(Prototype.Browser.MobileSafari){Prototype.BrowserFeatures.SpecificElementExtensions=false;}if(Prototype.Browser.WebKit){Prototype.BrowserFeatures.XPath=false;}var Class={create:function(){var E=null,D=$A(arguments);if(Object.isFunction(D[0])){E=D.shift();}function A(){this.initialize.apply(this,arguments);}Object.extend(A,Class.Methods);A.superclass=E;A.subclasses=[];if(E){var B=function(){};B.prototype=E.prototype;A.prototype=new B;E.subclasses.push(A);}for(var C=0;C<D.length;C++){A.addMethods(D[C]);}if(!A.prototype.initialize){A.prototype.initialize=Prototype.emptyFunction;}A.prototype.constructor=A;return A;}};Class.Methods={addMethods:function(G){var C=this.superclass&&this.superclass.prototype;var B=Object.keys(G);if(!Object.keys({toString:true}).length){B.push("toString","valueOf");}for(var A=0,D=B.length;A<D;A++){var F=B[A],E=G[F];if(C&&Object.isFunction(E)&&E.argumentNames().first()=="$super"){var H=E,E=Object.extend((function(I){return function(){return C[I].apply(this,arguments);};})(F).wrap(H),{valueOf:function(){return H;},toString:function(){return H.toString();}});}this.prototype[F]=E;}return this;}};var Abstract={};Object.extend=function(A,C){for(var B in C){A[B]=C[B];}return A;};Object.extend(Object,{inspect:function(A){try{if(A===undefined){return"undefined";}if(A===null){return"null";}return A.inspect?A.inspect():A.toString();}catch(B){if(B instanceof RangeError){return"...";}throw B;}},toJSON:function(A){var C=typeof A;switch(C){case"undefined":case"function":case"unknown":return ;case"boolean":return A.toString();}if(A===null){return"null";}if(A.toJSON){return A.toJSON();}if(Object.isElement(A)){return ;}var B=[];for(var E in A){var D=Object.toJSON(A[E]);if(D!==undefined){B.push(E.toJSON()+": "+D);}}return"{"+B.join(", ")+"}";},toQueryString:function(A){return $H(A).toQueryString();},toHTML:function(A){return A&&A.toHTML?A.toHTML():String.interpret(A);},keys:function(A){var B=[];for(var C in A){B.push(C);}return B;},values:function(B){var A=[];for(var C in B){A.push(B[C]);}return A;},clone:function(A){return Object.extend({},A);},isElement:function(A){return A&&A.nodeType==1;},isArray:function(A){return A&&A.constructor===Array;},isHash:function(A){return A instanceof Hash;},isFunction:function(A){return typeof A=="function";},isString:function(A){return typeof A=="string";},isNumber:function(A){return typeof A=="number";},isUndefined:function(A){return typeof A=="undefined";}});Object.extend(Function.prototype,{argumentNames:function(){var A=this.toString().match(/^[\s\(]*function[^(]*\((.*?)\)/)[1].split(",").invoke("strip");return A.length==1&&!A[0]?[]:A;},bind:function(){if(arguments.length<2&&arguments[0]===undefined){return this;}var A=this,C=$A(arguments),B=C.shift();return function(){return A.apply(B,C.concat($A(arguments)));};},bindAsEventListener:function(){var A=this,C=$A(arguments),B=C.shift();return function(D){return A.apply(B,[D||window.event].concat(C));};},curry:function(){if(!arguments.length){return this;}var A=this,B=$A(arguments);return function(){return A.apply(this,B.concat($A(arguments)));};},delay:function(){var A=this,B=$A(arguments),C=B.shift()*1000;return window.setTimeout(function(){return A.apply(A,B);},C);},wrap:function(B){var A=this;return function(){return B.apply(this,[A.bind(this)].concat($A(arguments)));};},methodize:function(){if(this._methodized){return this._methodized;}var A=this;return this._methodized=function(){return A.apply(null,[this].concat($A(arguments)));};}});Function.prototype.defer=Function.prototype.delay.curry(0.01);Date.prototype.toJSON=function(){return'"'+this.getUTCFullYear()+"-"+(this.getUTCMonth()+1).toPaddedString(2)+"-"+this.getUTCDate().toPaddedString(2)+"T"+this.getUTCHours().toPaddedString(2)+":"+this.getUTCMinutes().toPaddedString(2)+":"+this.getUTCSeconds().toPaddedString(2)+'Z"';};var Try={these:function(){var C;for(var B=0,D=arguments.length;B<D;B++){var A=arguments[B];try{C=A();break;}catch(E){}}return C;}};RegExp.prototype.match=RegExp.prototype.test;RegExp.escape=function(A){return String(A).replace(/([.*+?^=!:${}()|[\]\/\\])/g,"\\$1");};var PeriodicalExecuter=Class.create({initialize:function(B,A){this.callback=B;this.frequency=A;this.currentlyExecuting=false;this.registerCallback();},registerCallback:function(){this.timer=setInterval(this.onTimerEvent.bind(this),this.frequency*1000);},execute:function(){this.callback(this);},stop:function(){if(!this.timer){return ;}clearInterval(this.timer);this.timer=null;},onTimerEvent:function(){if(!this.currentlyExecuting){try{this.currentlyExecuting=true;this.execute();}finally{this.currentlyExecuting=false;}}}});Object.extend(String,{interpret:function(A){return A==null?"":String(A);},specialChar:{"\b":"\\b","\t":"\\t","\n":"\\n","\f":"\\f","\r":"\\r","\\":"\\\\"}});Object.extend(String.prototype,{gsub:function(E,C){var A="",D=this,B;C=arguments.callee.prepareReplacement(C);while(D.length>0){if(B=D.match(E)){A+=D.slice(0,B.index);A+=String.interpret(C(B));D=D.slice(B.index+B[0].length);}else{A+=D,D="";}}return A;},sub:function(C,A,B){A=this.gsub.prepareReplacement(A);B=B===undefined?1:B;return this.gsub(C,function(D){if(--B<0){return D[0];}return A(D);});},scan:function(B,A){this.gsub(B,A);return String(this);},truncate:function(B,A){B=B||30;A=A===undefined?"...":A;return this.length>B?this.slice(0,B-A.length)+A:String(this);},strip:function(){return this.replace(/^\s+/,"").replace(/\s+$/,"");},stripTags:function(){return this.replace(/<\/?[^>]+>/gi,"");},stripScripts:function(){return this.replace(new RegExp(Prototype.ScriptFragment,"img"),"");},extractScripts:function(){var B=new RegExp(Prototype.ScriptFragment,"img");var A=new RegExp(Prototype.ScriptFragment,"im");return(this.match(B)||[]).map(function(C){return(C.match(A)||["",""])[1];});},evalScripts:function(){return this.extractScripts().map(function(script){return eval(script);});},escapeHTML:function(){var A=arguments.callee;A.text.data=this;return A.div.innerHTML;},unescapeHTML:function(){var A=new Element("div");A.innerHTML=this.stripTags();return A.childNodes[0]?(A.childNodes.length>1?$A(A.childNodes).inject("",function(B,C){return B+C.nodeValue;}):A.childNodes[0].nodeValue):"";},toQueryParams:function(B){var A=this.strip().match(/([^?#]*)(#.*)?$/);if(!A){return{};}return A[1].split(B||"&").inject({},function(E,F){if((F=F.split("="))[0]){var C=decodeURIComponent(F.shift());var D=F.length>1?F.join("="):F[0];if(D!=undefined){D=decodeURIComponent(D);}if(C in E){if(!Object.isArray(E[C])){E[C]=[E[C]];}E[C].push(D);}else{E[C]=D;}}return E;});},toArray:function(){return this.split("");},succ:function(){return this.slice(0,this.length-1)+String.fromCharCode(this.charCodeAt(this.length-1)+1);},times:function(A){return A<1?"":new Array(A+1).join(this);},camelize:function(){var D=this.split("-"),A=D.length;if(A==1){return D[0];}var C=this.charAt(0)=="-"?D[0].charAt(0).toUpperCase()+D[0].substring(1):D[0];for(var B=1;B<A;B++){C+=D[B].charAt(0).toUpperCase()+D[B].substring(1);}return C;},capitalize:function(){return this.charAt(0).toUpperCase()+this.substring(1).toLowerCase();},underscore:function(){return this.gsub(/::/,"/").gsub(/([A-Z]+)([A-Z][a-z])/,"#{1}_#{2}").gsub(/([a-z\d])([A-Z])/,"#{1}_#{2}").gsub(/-/,"_").toLowerCase();},dasherize:function(){return this.gsub(/_/,"-");},inspect:function(B){var A=this.gsub(/[\x00-\x1f\\]/,function(C){var D=String.specialChar[C[0]];return D?D:"\\u00"+C[0].charCodeAt().toPaddedString(2,16);});if(B){return'"'+A.replace(/"/g,'\\"')+'"';}return"'"+A.replace(/'/g,"\\'")+"'";},toJSON:function(){return this.inspect(true);},unfilterJSON:function(A){return this.sub(A||Prototype.JSONFilter,"#{1}");},isJSON:function(){var A=this.replace(/\\./g,"@").replace(/"[^"\\\n\r]*"/g,"");return(/^[,:{}\[\]0-9.\-+Eaeflnr-u \n\r\t]*$/).test(A);},evalJSON:function(sanitize){var json=this.unfilterJSON();try{if(!sanitize||json.isJSON()){return eval("("+json+")");}}catch(e){}throw new SyntaxError("Badly formed JSON string: "+this.inspect());},include:function(A){return this.indexOf(A)>-1;},startsWith:function(A){return this.indexOf(A)===0;},endsWith:function(A){var B=this.length-A.length;return B>=0&&this.lastIndexOf(A)===B;},empty:function(){return this=="";},blank:function(){return/^\s*$/.test(this);},interpolate:function(A,B){return new Template(this,B).evaluate(A);}});if(Prototype.Browser.WebKit||Prototype.Browser.IE){Object.extend(String.prototype,{escapeHTML:function(){return this.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");},unescapeHTML:function(){return this.replace(/&amp;/g,"&").replace(/&lt;/g,"<").replace(/&gt;/g,">");}});}String.prototype.gsub.prepareReplacement=function(B){if(Object.isFunction(B)){return B;}var A=new Template(B);return function(C){return A.evaluate(C);};};String.prototype.parseQuery=String.prototype.toQueryParams;Object.extend(String.prototype.escapeHTML,{div:document.createElement("div"),text:document.createTextNode("")});with(String.prototype.escapeHTML){div.appendChild(text);}var Template=Class.create({initialize:function(A,B){this.template=A.toString();this.pattern=B||Template.Pattern;},evaluate:function(A){if(Object.isFunction(A.toTemplateReplacements)){A=A.toTemplateReplacements();}return this.template.gsub(this.pattern,function(D){if(A==null){return"";}var F=D[1]||"";if(F=="\\"){return D[2];}var B=A,G=D[3];var E=/^([^.[]+|\[((?:.*?[^\\])?)\])(\.|\[|$)/,D=E.exec(G);if(D==null){return F;}while(D!=null){var C=D[1].startsWith("[")?D[2].gsub("\\\\]","]"):D[1];B=B[C];if(null==B||""==D[3]){break;}G=G.substring("["==D[3]?D[1].length:D[0].length);D=E.exec(G);}return F+String.interpret(B);}.bind(this));}});Template.Pattern=/(^|.|\r|\n)(#\{(.*?)\})/;var $break={};var Enumerable={each:function(C,B){var A=0;C=C.bind(B);try{this._each(function(E){C(E,A++);});}catch(D){if(D!=$break){throw D;}}return this;},eachSlice:function(D,C,B){C=C?C.bind(B):Prototype.K;var A=-D,E=[],F=this.toArray();while((A+=D)<F.length){E.push(F.slice(A,A+D));}return E.collect(C,B);},all:function(C,B){C=C?C.bind(B):Prototype.K;var A=true;this.each(function(E,D){A=A&&!!C(E,D);if(!A){throw $break;}});return A;},any:function(C,B){C=C?C.bind(B):Prototype.K;var A=false;this.each(function(E,D){if(A=!!C(E,D)){throw $break;}});return A;},collect:function(C,B){C=C?C.bind(B):Prototype.K;var A=[];this.each(function(E,D){A.push(C(E,D));});return A;},detect:function(C,B){C=C.bind(B);var A;this.each(function(E,D){if(C(E,D)){A=E;throw $break;}});return A;},findAll:function(C,B){C=C.bind(B);var A=[];this.each(function(E,D){if(C(E,D)){A.push(E);}});return A;},grep:function(D,C,B){C=C?C.bind(B):Prototype.K;var A=[];if(Object.isString(D)){D=new RegExp(D);}this.each(function(F,E){if(D.match(F)){A.push(C(F,E));}});return A;},include:function(A){if(Object.isFunction(this.indexOf)){if(this.indexOf(A)!=-1){return true;}}var B=false;this.each(function(C){if(C==A){B=true;throw $break;}});return B;},inGroupsOf:function(B,A){A=A===undefined?null:A;return this.eachSlice(B,function(C){while(C.length<B){C.push(A);}return C;});},inject:function(A,C,B){C=C.bind(B);this.each(function(E,D){A=C(A,E,D);});return A;},invoke:function(B){var A=$A(arguments).slice(1);return this.map(function(C){return C[B].apply(C,A);});},max:function(C,B){C=C?C.bind(B):Prototype.K;var A;this.each(function(E,D){E=C(E,D);if(A==undefined||E>=A){A=E;}});return A;},min:function(C,B){C=C?C.bind(B):Prototype.K;var A;this.each(function(E,D){E=C(E,D);if(A==undefined||E<A){A=E;}});return A;},partition:function(D,B){D=D?D.bind(B):Prototype.K;var C=[],A=[];this.each(function(F,E){(D(F,E)?C:A).push(F);});return[C,A];},pluck:function(B){var A=[];this.each(function(C){A.push(C[B]);});return A;},reject:function(C,B){C=C.bind(B);var A=[];this.each(function(E,D){if(!C(E,D)){A.push(E);}});return A;},sortBy:function(B,A){B=B.bind(A);return this.map(function(D,C){return{value:D,criteria:B(D,C)};}).sort(function(F,E){var D=F.criteria,C=E.criteria;return D<C?-1:D>C?1:0;}).pluck("value");},toArray:function(){return this.map();},zip:function(){var B=Prototype.K,A=$A(arguments);if(Object.isFunction(A.last())){B=A.pop();}var C=[this].concat(A).map($A);return this.map(function(E,D){return B(C.pluck(D));});},size:function(){return this.toArray().length;},inspect:function(){return"#<Enumerable:"+this.toArray().inspect()+">";}};Object.extend(Enumerable,{map:Enumerable.collect,find:Enumerable.detect,select:Enumerable.findAll,filter:Enumerable.findAll,member:Enumerable.include,entries:Enumerable.toArray,every:Enumerable.all,some:Enumerable.any});function $A(C){if(!C){return[];}if(C.toArray){return C.toArray();}var B=C.length,A=new Array(B);while(B--){A[B]=C[B];}return A;}if(Prototype.Browser.WebKit){function $A(C){if(!C){return[];}if(!(Object.isFunction(C)&&C=="[object NodeList]")&&C.toArray){return C.toArray();}var B=C.length,A=new Array(B);while(B--){A[B]=C[B];}return A;}}Array.from=$A;Object.extend(Array.prototype,Enumerable);if(!Array.prototype._reverse){Array.prototype._reverse=Array.prototype.reverse;}Object.extend(Array.prototype,{_each:function(B){for(var A=0,C=this.length;A<C;A++){B(this[A]);}},clear:function(){this.length=0;return this;},first:function(){return this[0];},last:function(){return this[this.length-1];},compact:function(){return this.select(function(A){return A!=null;});},flatten:function(){return this.inject([],function(B,A){return B.concat(Object.isArray(A)?A.flatten():[A]);});},without:function(){var A=$A(arguments);return this.select(function(B){return !A.include(B);});},reverse:function(A){return(A!==false?this:this.toArray())._reverse();},reduce:function(){return this.length>1?this:this[0];},uniq:function(A){return this.inject([],function(D,C,B){if(0==B||(A?D.last()!=C:!D.include(C))){D.push(C);}return D;});},intersect:function(A){return this.uniq().findAll(function(B){return A.detect(function(C){return B===C;});});},clone:function(){return[].concat(this);},size:function(){return this.length;},inspect:function(){return"["+this.map(Object.inspect).join(", ")+"]";},toJSON:function(){var A=[];this.each(function(B){var C=Object.toJSON(B);if(C!==undefined){A.push(C);}});return"["+A.join(", ")+"]";}});if(Object.isFunction(Array.prototype.forEach)){Array.prototype._each=Array.prototype.forEach;}if(!Array.prototype.indexOf){Array.prototype.indexOf=function(C,A){A||(A=0);var B=this.length;if(A<0){A=B+A;}for(;A<B;A++){if(this[A]===C){return A;}}return -1;};}if(!Array.prototype.lastIndexOf){Array.prototype.lastIndexOf=function(B,A){A=isNaN(A)?this.length:(A<0?this.length+A:A)+1;var C=this.slice(0,A).reverse().indexOf(B);return(C<0)?C:A-C-1;};}Array.prototype.toArray=Array.prototype.clone;function $w(A){if(!Object.isString(A)){return[];}A=A.strip();return A?A.split(/\s+/):[];}if(Prototype.Browser.Opera){Array.prototype.concat=function(){var E=[];for(var B=0,C=this.length;B<C;B++){E.push(this[B]);}for(var B=0,C=arguments.length;B<C;B++){if(Object.isArray(arguments[B])){for(var A=0,D=arguments[B].length;A<D;A++){E.push(arguments[B][A]);}}else{E.push(arguments[B]);}}return E;};}Object.extend(Number.prototype,{toColorPart:function(){return this.toPaddedString(2,16);},succ:function(){return this+1;},times:function(A){$R(0,this,true).each(A);return this;},toPaddedString:function(C,B){var A=this.toString(B||10);return"0".times(C-A.length)+A;},toJSON:function(){return isFinite(this)?this.toString():"null";}});$w("abs round ceil floor").each(function(A){Number.prototype[A]=Math[A].methodize();});function $H(A){return new Hash(A);}var Hash=Class.create(Enumerable,(function(){if(function(){var C=0,E=function(F){this.key=F;};E.prototype.key="foo";for(var D in new E("bar")){C++;}return C>1;}()){function B(E){var C=[];for(var D in this._object){var F=this._object[D];if(C.include(D)){continue;}C.push(D);var G=[D,F];G.key=D;G.value=F;E(G);}}}else{function B(D){for(var C in this._object){var E=this._object[C],F=[C,E];F.key=C;F.value=E;D(F);}}}function A(C,D){if(Object.isUndefined(D)){return C;}return C+"="+encodeURIComponent(String.interpret(D));}return{initialize:function(C){this._object=Object.isHash(C)?C.toObject():Object.clone(C);},_each:B,set:function(C,D){return this._object[C]=D;},get:function(C){return this._object[C];},unset:function(C){var D=this._object[C];delete this._object[C];return D;},toObject:function(){return Object.clone(this._object);},keys:function(){return this.pluck("key");},values:function(){return this.pluck("value");},index:function(D){var C=this.detect(function(E){return E.value===D;});return C&&C.key;},merge:function(C){return this.clone().update(C);},update:function(C){return new Hash(C).inject(this,function(D,E){D.set(E.key,E.value);return D;});},toQueryString:function(){return this.map(function(E){var D=encodeURIComponent(E.key),C=E.value;if(C&&typeof C=="object"){if(Object.isArray(C)){return C.map(A.curry(D)).join("&");}}return A(D,C);}).join("&");},inspect:function(){return"#<Hash:{"+this.map(function(C){return C.map(Object.inspect).join(": ");}).join(", ")+"}>";},toJSON:function(){return Object.toJSON(this.toObject());},clone:function(){return new Hash(this);}};})());Hash.prototype.toTemplateReplacements=Hash.prototype.toObject;Hash.from=$H;var ObjectRange=Class.create(Enumerable,{initialize:function(C,A,B){this.start=C;this.end=A;this.exclusive=B;},_each:function(A){var B=this.start;while(this.include(B)){A(B);B=B.succ();}},include:function(A){if(A<this.start){return false;}if(this.exclusive){return A<this.end;}return A<=this.end;}});var $R=function(C,A,B){return new ObjectRange(C,A,B);};var Ajax={getTransport:function(){return Try.these(function(){return new XMLHttpRequest();},function(){return new ActiveXObject("Msxml2.XMLHTTP");},function(){return new ActiveXObject("Microsoft.XMLHTTP");})||false;},activeRequestCount:0};Ajax.Responders={responders:[],_each:function(A){this.responders._each(A);},register:function(A){if(!this.include(A)){this.responders.push(A);}},unregister:function(A){this.responders=this.responders.without(A);},dispatch:function(D,B,C,A){this.each(function(E){if(Object.isFunction(E[D])){try{E[D].apply(E,[B,C,A]);}catch(F){}}});}};Object.extend(Ajax.Responders,Enumerable);Ajax.Responders.register({onCreate:function(){Ajax.activeRequestCount++;},onComplete:function(){Ajax.activeRequestCount--;}});Ajax.Base=Class.create({initialize:function(A){this.options={method:"post",asynchronous:true,contentType:"application/x-www-form-urlencoded",encoding:"UTF-8",parameters:"",evalJSON:true,evalJS:true};Object.extend(this.options,A||{});this.options.method=this.options.method.toLowerCase();if(Object.isString(this.options.parameters)){this.options.parameters=this.options.parameters.toQueryParams();}}});Ajax.Request=Class.create(Ajax.Base,{_complete:false,initialize:function($super,B,A){$super(A);this.transport=Ajax.getTransport();this.request(B);},request:function(B){this.url=B;this.method=this.options.method;var D=Object.clone(this.options.parameters);if(!["get","post"].include(this.method)){D["_method"]=this.method;this.method="post";}this.parameters=D;if(D=Object.toQueryString(D)){if(this.method=="get"){this.url+=(this.url.include("?")?"&":"?")+D;}else{if(/Konqueror|Safari|KHTML/.test(navigator.userAgent)){D+="&_=";}}}try{var A=new Ajax.Response(this);if(this.options.onCreate){this.options.onCreate(A);}Ajax.Responders.dispatch("onCreate",this,A);this.transport.open(this.method.toUpperCase(),this.url,this.options.asynchronous);if(this.options.asynchronous){this.respondToReadyState.bind(this).defer(1);}this.transport.onreadystatechange=this.onStateChange.bind(this);this.setRequestHeaders();this.body=this.method=="post"?(this.options.postBody||D):null;this.transport.send(this.body);if(!this.options.asynchronous&&this.transport.overrideMimeType){this.onStateChange();}}catch(C){this.dispatchException(C);}},onStateChange:function(){var A=this.transport.readyState;if(A>1&&!((A==4)&&this._complete)){this.respondToReadyState(this.transport.readyState);}},setRequestHeaders:function(){var E={"X-Requested-With":"XMLHttpRequest","X-Prototype-Version":Prototype.Version,"Accept":"text/javascript, text/html, application/xml, text/xml, */*"};if(this.method=="post"){E["Content-type"]=this.options.contentType+(this.options.encoding?"; charset="+this.options.encoding:"");if(this.transport.overrideMimeType&&(navigator.userAgent.match(/Gecko\/(\d{4})/)||[0,2005])[1]<2005){E["Connection"]="close";}}if(typeof this.options.requestHeaders=="object"){var C=this.options.requestHeaders;if(Object.isFunction(C.push)){for(var B=0,D=C.length;B<D;B+=2){E[C[B]]=C[B+1];}}else{$H(C).each(function(F){E[F.key]=F.value;});}}for(var A in E){this.transport.setRequestHeader(A,E[A]);}},success:function(){var A=this.getStatus();return !A||(A>=200&&A<300);},getStatus:function(){try{return this.transport.status||0;}catch(A){return 0;}},respondToReadyState:function(A){var C=Ajax.Request.Events[A],B=new Ajax.Response(this);if(C=="Complete"){try{this._complete=true;(this.options["on"+B.status]||this.options["on"+(this.success()?"Success":"Failure")]||Prototype.emptyFunction)(B,B.headerJSON);}catch(D){this.dispatchException(D);}var E=B.getHeader("Content-type");if(this.options.evalJS=="force"||(this.options.evalJS&&E&&E.match(/^\s*(text|application)\/(x-)?(java|ecma)script(;.*)?\s*$/i))){this.evalResponse();}}try{(this.options["on"+C]||Prototype.emptyFunction)(B,B.headerJSON);Ajax.Responders.dispatch("on"+C,this,B,B.headerJSON);}catch(D){this.dispatchException(D);}if(C=="Complete"){this.transport.onreadystatechange=Prototype.emptyFunction;}},getHeader:function(A){try{return this.transport.getResponseHeader(A);}catch(B){return null;}},evalResponse:function(){try{return eval((this.transport.responseText||"").unfilterJSON());}catch(e){this.dispatchException(e);}},dispatchException:function(A){(this.options.onException||Prototype.emptyFunction)(this,A);Ajax.Responders.dispatch("onException",this,A);}});Ajax.Request.Events=["Uninitialized","Loading","Loaded","Interactive","Complete"];Ajax.Response=Class.create({initialize:function(C){this.request=C;var D=this.transport=C.transport,A=this.readyState=D.readyState;if((A>2&&!Prototype.Browser.IE)||A==4){this.status=this.getStatus();this.statusText=this.getStatusText();this.responseText=String.interpret(D.responseText);this.headerJSON=this._getHeaderJSON();}if(A==4){var B=D.responseXML;this.responseXML=B===undefined?null:B;this.responseJSON=this._getResponseJSON();}},status:0,statusText:"",getStatus:Ajax.Request.prototype.getStatus,getStatusText:function(){try{return this.transport.statusText||"";}catch(A){return"";}},getHeader:Ajax.Request.prototype.getHeader,getAllHeaders:function(){try{return this.getAllResponseHeaders();}catch(A){return null;}},getResponseHeader:function(A){return this.transport.getResponseHeader(A);},getAllResponseHeaders:function(){return this.transport.getAllResponseHeaders();},_getHeaderJSON:function(){var A=this.getHeader("X-JSON");if(!A){return null;}A=decodeURIComponent(escape(A));try{return A.evalJSON(this.request.options.sanitizeJSON);}catch(B){this.request.dispatchException(B);}},_getResponseJSON:function(){var A=this.request.options;if(!A.evalJSON||(A.evalJSON!="force"&&!(this.getHeader("Content-type")||"").include("application/json"))){return null;}try{return this.transport.responseText.evalJSON(A.sanitizeJSON);}catch(B){this.request.dispatchException(B);}}});Ajax.Updater=Class.create(Ajax.Request,{initialize:function($super,A,C,B){this.container={success:(A.success||A),failure:(A.failure||(A.success?null:A))};B=B||{};var D=B.onComplete;B.onComplete=(function(E,F){this.updateContent(E.responseText);if(Object.isFunction(D)){D(E,F);}}).bind(this);$super(C,B);},updateContent:function(D){var C=this.container[this.success()?"success":"failure"],A=this.options;if(!A.evalScripts){D=D.stripScripts();}if(C=$(C)){if(A.insertion){if(Object.isString(A.insertion)){var B={};B[A.insertion]=D;C.insert(B);}else{A.insertion(C,D);}}else{C.update(D);}}if(this.success()){if(this.onComplete){this.onComplete.bind(this).defer();}}}});Ajax.PeriodicalUpdater=Class.create(Ajax.Base,{initialize:function($super,A,C,B){$super(B);this.onComplete=this.options.onComplete;this.frequency=(this.options.frequency||2);this.decay=(this.options.decay||1);this.updater={};this.container=A;this.url=C;this.start();},start:function(){this.options.onComplete=this.updateComplete.bind(this);this.onTimerEvent();},stop:function(){this.updater.options.onComplete=undefined;clearTimeout(this.timer);(this.onComplete||Prototype.emptyFunction).apply(this,arguments);},updateComplete:function(A){if(this.options.decay){this.decay=(A.responseText==this.lastText?this.decay*this.options.decay:1);this.lastText=A.responseText;}this.timer=this.onTimerEvent.bind(this).delay(this.decay*this.frequency);},onTimerEvent:function(){this.updater=new Ajax.Updater(this.container,this.url,this.options);}});function $(B){if(arguments.length>1){for(var A=0,D=[],C=arguments.length;A<C;A++){D.push($(arguments[A]));}return D;}if(Object.isString(B)){B=document.getElementById(B);}return Element.extend(B);}if(Prototype.BrowserFeatures.XPath){document._getElementsByXPath=function(F,A){var C=[];var E=document.evaluate(F,$(A)||document,null,XPathResult.ORDERED_NODE_SNAPSHOT_TYPE,null);for(var B=0,D=E.snapshotLength;B<D;B++){C.push(Element.extend(E.snapshotItem(B)));}return C;};}if(!window.Node){var Node={};}if(!Node.ELEMENT_NODE){Object.extend(Node,{ELEMENT_NODE:1,ATTRIBUTE_NODE:2,TEXT_NODE:3,CDATA_SECTION_NODE:4,ENTITY_REFERENCE_NODE:5,ENTITY_NODE:6,PROCESSING_INSTRUCTION_NODE:7,COMMENT_NODE:8,DOCUMENT_NODE:9,DOCUMENT_TYPE_NODE:10,DOCUMENT_FRAGMENT_NODE:11,NOTATION_NODE:12});}(function(){var A=this.Element;this.Element=function(D,C){C=C||{};D=D.toLowerCase();var B=Element.cache;if(Prototype.Browser.IE&&C.name){D="<"+D+' name="'+C.name+'">';delete C.name;return Element.writeAttribute(document.createElement(D),C);}if(!B[D]){B[D]=Element.extend(document.createElement(D));}return Element.writeAttribute(B[D].cloneNode(false),C);};Object.extend(this.Element,A||{});}).call(window);Element.cache={};Element.Methods={visible:function(A){return $(A).style.display!="none";},toggle:function(A){A=$(A);Element[Element.visible(A)?"hide":"show"](A);return A;},hide:function(A){$(A).style.display="none";return A;},show:function(A){$(A).style.display="";return A;},remove:function(A){A=$(A);A.parentNode.removeChild(A);return A;},update:function(A,B){A=$(A);if(B&&B.toElement){B=B.toElement();}if(Object.isElement(B)){return A.update().insert(B);}B=Object.toHTML(B);A.innerHTML=B.stripScripts();B.evalScripts.bind(B).defer();return A;},replace:function(B,C){B=$(B);if(C&&C.toElement){C=C.toElement();}else{if(!Object.isElement(C)){C=Object.toHTML(C);var A=B.ownerDocument.createRange();A.selectNode(B);C.evalScripts.bind(C).defer();C=A.createContextualFragment(C.stripScripts());}}B.parentNode.replaceChild(C,B);return B;},insert:function(C,E){C=$(C);if(Object.isString(E)||Object.isNumber(E)||Object.isElement(E)||(E&&(E.toElement||E.toHTML))){E={bottom:E};}var D,B,A;for(position in E){D=E[position];position=position.toLowerCase();B=Element._insertionTranslations[position];if(D&&D.toElement){D=D.toElement();}if(Object.isElement(D)){B.insert(C,D);continue;}D=Object.toHTML(D);A=C.ownerDocument.createRange();B.initializeRange(C,A);B.insert(C,A.createContextualFragment(D.stripScripts()));D.evalScripts.bind(D).defer();}return C;},wrap:function(B,C,A){B=$(B);if(Object.isElement(C)){$(C).writeAttribute(A||{});}else{if(Object.isString(C)){C=new Element(C,A);}else{C=new Element("div",C);}}if(B.parentNode){B.parentNode.replaceChild(C,B);}C.appendChild(B);return C;},inspect:function(B){B=$(B);var A="<"+B.tagName.toLowerCase();$H({"id":"id","className":"class"}).each(function(F){var E=F.first(),C=F.last();var D=(B[E]||"").toString();if(D){A+=" "+C+"="+D.inspect(true);}});return A+">";},recursivelyCollect:function(A,C){A=$(A);var B=[];while(A=A[C]){if(A.nodeType==1){B.push(Element.extend(A));}}return B;},ancestors:function(A){return $(A).recursivelyCollect("parentNode");},descendants:function(A){return $A($(A).getElementsByTagName("*")).each(Element.extend);},firstDescendant:function(A){A=$(A).firstChild;while(A&&A.nodeType!=1){A=A.nextSibling;}return $(A);},immediateDescendants:function(A){if(!(A=$(A).firstChild)){return[];}while(A&&A.nodeType!=1){A=A.nextSibling;}if(A){return[A].concat($(A).nextSiblings());}return[];},previousSiblings:function(A){return $(A).recursivelyCollect("previousSibling");},nextSiblings:function(A){return $(A).recursivelyCollect("nextSibling");},siblings:function(A){A=$(A);return A.previousSiblings().reverse().concat(A.nextSiblings());},match:function(B,A){if(Object.isString(A)){A=new Selector(A);}return A.match($(B));},up:function(B,D,A){B=$(B);if(arguments.length==1){return $(B.parentNode);}var C=B.ancestors();return D?Selector.findElement(C,D,A):C[A||0];},down:function(B,C,A){B=$(B);if(arguments.length==1){return B.firstDescendant();}var D=B.descendants();return C?Selector.findElement(D,C,A):D[A||0];},previous:function(B,D,A){B=$(B);if(arguments.length==1){return $(Selector.handlers.previousElementSibling(B));}var C=B.previousSiblings();return D?Selector.findElement(C,D,A):C[A||0];},next:function(C,D,B){C=$(C);if(arguments.length==1){return $(Selector.handlers.nextElementSibling(C));}var A=C.nextSiblings();return D?Selector.findElement(A,D,B):A[B||0];},select:function(){var A=$A(arguments),B=$(A.shift());return Selector.findChildElements(B,A);},adjacent:function(){var A=$A(arguments),B=$(A.shift());return Selector.findChildElements(B.parentNode,A).without(B);},identify:function(B){B=$(B);var C=B.readAttribute("id"),A=arguments.callee;if(C){return C;}do{C="anonymous_element_"+A.counter++;}while($(C));B.writeAttribute("id",C);return C;},readAttribute:function(C,A){C=$(C);if(Prototype.Browser.IE){var B=Element._attributeTranslations.read;if(B.values[A]){return B.values[A](C,A);}if(B.names[A]){A=B.names[A];}if(A.include(":")){return(!C.attributes||!C.attributes[A])?null:C.attributes[A].value;}}return C.getAttribute(A);},writeAttribute:function(E,C,F){E=$(E);var B={},D=Element._attributeTranslations.write;if(typeof C=="object"){B=C;}else{B[C]=F===undefined?true:F;}for(var A in B){var C=D.names[A]||A,F=B[A];if(D.values[A]){C=D.values[A](E,F);}if(F===false||F===null){E.removeAttribute(C);}else{if(F===true){E.setAttribute(C,C);}else{E.setAttribute(C,F);}}}return E;},getHeight:function(A){return $(A).getDimensions().height;},getWidth:function(A){return $(A).getDimensions().width;},classNames:function(A){return new Element.ClassNames(A);},hasClassName:function(A,B){if(!(A=$(A))){return ;}var C=A.className;return(C.length>0&&(C==B||new RegExp("(^|\\s)"+B+"(\\s|$)").test(C)));},addClassName:function(A,B){if(!(A=$(A))){return ;}if(!A.hasClassName(B)){A.className+=(A.className?" ":"")+B;}return A;},removeClassName:function(A,B){if(!(A=$(A))){return ;}A.className=A.className.replace(new RegExp("(^|\\s+)"+B+"(\\s+|$)")," ").strip();return A;},toggleClassName:function(A,B){if(!(A=$(A))){return ;}return A[A.hasClassName(B)?"removeClassName":"addClassName"](B);},cleanWhitespace:function(B){B=$(B);var C=B.firstChild;while(C){var A=C.nextSibling;if(C.nodeType==3&&!/\S/.test(C.nodeValue)){B.removeChild(C);}C=A;}return B;},empty:function(A){return $(A).innerHTML.blank();},descendantOf:function(D,C){D=$(D),C=$(C);if(D.compareDocumentPosition){return(D.compareDocumentPosition(C)&8)===8;}if(D.sourceIndex&&!Prototype.Browser.Opera){var E=D.sourceIndex,B=C.sourceIndex,A=C.nextSibling;if(!A){do{C=C.parentNode;}while(!(A=C.nextSibling)&&C.parentNode);}if(A){return(E>B&&E<A.sourceIndex);}}while(D=D.parentNode){if(D==C){return true;}}return false;},scrollTo:function(A){A=$(A);var B=A.cumulativeOffset();window.scrollTo(B[0],B[1]);return A;},getStyle:function(B,C){B=$(B);C=C=="float"?"cssFloat":C.camelize();var D=B.style[C];if(!D){var A=document.defaultView.getComputedStyle(B,null);D=A?A[C]:null;}if(C=="opacity"){return D?parseFloat(D):1;}return D=="auto"?null:D;},getOpacity:function(A){return $(A).getStyle("opacity");},setStyle:function(B,C){B=$(B);var E=B.style,A;if(Object.isString(C)){B.style.cssText+=";"+C;return C.include("opacity")?B.setOpacity(C.match(/opacity:\s*(\d?\.?\d*)/)[1]):B;}for(var D in C){if(D=="opacity"){B.setOpacity(C[D]);}else{E[(D=="float"||D=="cssFloat")?(E.styleFloat===undefined?"cssFloat":"styleFloat"):D]=C[D];}}return B;},setOpacity:function(A,B){A=$(A);A.style.opacity=(B==1||B==="")?"":(B<0.00001)?0:B;return A;},getDimensions:function(C){C=$(C);var G=$(C).getStyle("display");if(G!="none"&&G!=null){return{width:C.offsetWidth,height:C.offsetHeight};}var B=C.style;var F=B.visibility;var D=B.position;var A=B.display;B.visibility="hidden";B.position="absolute";B.display="block";var H=C.clientWidth;var E=C.clientHeight;B.display=A;B.position=D;B.visibility=F;return{width:H,height:E};},makePositioned:function(A){A=$(A);var B=Element.getStyle(A,"position");if(B=="static"||!B){A._madePositioned=true;A.style.position="relative";if(window.opera){A.style.top=0;A.style.left=0;}}return A;},undoPositioned:function(A){A=$(A);if(A._madePositioned){A._madePositioned=undefined;A.style.position=A.style.top=A.style.left=A.style.bottom=A.style.right="";}return A;},makeClipping:function(A){A=$(A);if(A._overflow){return A;}A._overflow=Element.getStyle(A,"overflow")||"auto";if(A._overflow!=="hidden"){A.style.overflow="hidden";}return A;},undoClipping:function(A){A=$(A);if(!A._overflow){return A;}A.style.overflow=A._overflow=="auto"?"":A._overflow;A._overflow=null;return A;},cumulativeOffset:function(B){var A=0,C=0;do{A+=B.offsetTop||0;C+=B.offsetLeft||0;B=B.offsetParent;}while(B);return Element._returnOffset(C,A);},positionedOffset:function(B){var A=0,D=0;do{A+=B.offsetTop||0;D+=B.offsetLeft||0;B=B.offsetParent;if(B){if(B.tagName=="BODY"){break;}var C=Element.getStyle(B,"position");if(C=="relative"||C=="absolute"){break;}}}while(B);return Element._returnOffset(D,A);},absolutize:function(B){B=$(B);if(B.getStyle("position")=="absolute"){return ;}var D=B.positionedOffset();var F=D[1];var E=D[0];var C=B.clientWidth;var A=B.clientHeight;B._originalLeft=E-parseFloat(B.style.left||0);B._originalTop=F-parseFloat(B.style.top||0);B._originalWidth=B.style.width;B._originalHeight=B.style.height;B.style.position="absolute";B.style.top=F+"px";B.style.left=E+"px";B.style.width=C+"px";B.style.height=A+"px";return B;},relativize:function(A){A=$(A);if(A.getStyle("position")=="relative"){return ;}A.style.position="relative";var C=parseFloat(A.style.top||0)-(A._originalTop||0);var B=parseFloat(A.style.left||0)-(A._originalLeft||0);A.style.top=C+"px";A.style.left=B+"px";A.style.height=A._originalHeight;A.style.width=A._originalWidth;return A;},cumulativeScrollOffset:function(B){var A=0,C=0;do{A+=B.scrollTop||0;C+=B.scrollLeft||0;B=B.parentNode;}while(B);return Element._returnOffset(C,A);},getOffsetParent:function(A){if(A.offsetParent){return $(A.offsetParent);}if(A==document.body){return $(A);}while((A=A.parentNode)&&A!=document.body){if(Element.getStyle(A,"position")!="static"){return $(A);}}return $(document.body);},viewportOffset:function(D){var A=0,C=0;var B=D;do{A+=B.offsetTop||0;C+=B.offsetLeft||0;if(B.offsetParent==document.body&&Element.getStyle(B,"position")=="absolute"){break;}}while(B=B.offsetParent);B=D;do{if(!Prototype.Browser.Opera||B.tagName=="BODY"){A-=B.scrollTop||0;C-=B.scrollLeft||0;}}while(B=B.parentNode);return Element._returnOffset(C,A);},clonePosition:function(B,D){var A=Object.extend({setLeft:true,setTop:true,setWidth:true,setHeight:true,offsetTop:0,offsetLeft:0},arguments[2]||{});D=$(D);var E=D.viewportOffset();B=$(B);var F=[0,0];var C=null;if(Element.getStyle(B,"position")=="absolute"){C=B.getOffsetParent();F=C.viewportOffset();}if(C==document.body){F[0]-=document.body.offsetLeft;F[1]-=document.body.offsetTop;}if(A.setLeft){B.style.left=(E[0]-F[0]+A.offsetLeft)+"px";}if(A.setTop){B.style.top=(E[1]-F[1]+A.offsetTop)+"px";}if(A.setWidth){B.style.width=D.offsetWidth+"px";}if(A.setHeight){B.style.height=D.offsetHeight+"px";}return B;}};Element.Methods.identify.counter=1;Object.extend(Element.Methods,{getElementsBySelector:Element.Methods.select,childElements:Element.Methods.immediateDescendants});Element._attributeTranslations={write:{names:{className:"class",htmlFor:"for"},values:{}}};if(!document.createRange||Prototype.Browser.Opera){Element.Methods.insert=function(E,G){E=$(E);if(Object.isString(G)||Object.isNumber(G)||Object.isElement(G)||(G&&(G.toElement||G.toHTML))){G={bottom:G};}var D=Element._insertionTranslations,F,B,H,C;for(B in G){F=G[B];B=B.toLowerCase();H=D[B];if(F&&F.toElement){F=F.toElement();}if(Object.isElement(F)){H.insert(E,F);continue;}F=Object.toHTML(F);C=((B=="before"||B=="after")?E.parentNode:E).tagName.toUpperCase();if(D.tags[C]){var A=Element._getContentFromAnonymousElement(C,F.stripScripts());if(B=="top"||B=="after"){A.reverse();}A.each(H.insert.curry(E));}else{E.insertAdjacentHTML(H.adjacency,F.stripScripts());}F.evalScripts.bind(F).defer();}return E;};}if(Prototype.Browser.Opera){Element.Methods._getStyle=Element.Methods.getStyle;Element.Methods.getStyle=function(A,B){switch(B){case"left":case"top":case"right":case"bottom":if(Element._getStyle(A,"position")=="static"){return null;}default:return Element._getStyle(A,B);}};Element.Methods._readAttribute=Element.Methods.readAttribute;Element.Methods.readAttribute=function(A,B){if(B=="title"){return A.title;}return Element._readAttribute(A,B);};}else{if(Prototype.Browser.IE){$w("positionedOffset getOffsetParent viewportOffset").each(function(A){Element.Methods[A]=Element.Methods[A].wrap(function(D,C){C=$(C);var B=C.getStyle("position");if(B!="static"){return D(C);}C.setStyle({position:"relative"});var E=D(C);C.setStyle({position:B});return E;});});Element.Methods.getStyle=function(A,B){A=$(A);B=(B=="float"||B=="cssFloat")?"styleFloat":B.camelize();var C=A.style[B];if(!C&&A.currentStyle){C=A.currentStyle[B];}if(B=="opacity"){if(C=(A.getStyle("filter")||"").match(/alpha\(opacity=(.*)\)/)){if(C[1]){return parseFloat(C[1])/100;}}return 1;}if(C=="auto"){if((B=="width"||B=="height")&&(A.getStyle("display")!="none")){return A["offset"+B.capitalize()]+"px";}return null;}return C;};Element.Methods.setOpacity=function(B,E){function F(G){return G.replace(/alpha\([^\)]*\)/gi,"");}B=$(B);var A=B.currentStyle;if((A&&!A.hasLayout)||(!A&&B.style.zoom=="normal")){B.style.zoom=1;}var D=B.getStyle("filter"),C=B.style;if(E==1||E===""){(D=F(D))?C.filter=D:C.removeAttribute("filter");return B;}else{if(E<0.00001){E=0;}}C.filter=F(D)+"alpha(opacity="+(E*100)+")";return B;};Element._attributeTranslations={read:{names:{"class":"className","for":"htmlFor"},values:{_getAttr:function(A,B){return A.getAttribute(B,2);},_getAttrNode:function(A,C){var B=A.getAttributeNode(C);return B?B.value:"";},_getEv:function(A,B){var B=A.getAttribute(B);return B?B.toString().slice(23,-2):null;},_flag:function(A,B){return $(A).hasAttribute(B)?B:null;},style:function(A){return A.style.cssText.toLowerCase();},title:function(A){return A.title;}}}};Element._attributeTranslations.write={names:Object.clone(Element._attributeTranslations.read.names),values:{checked:function(A,B){A.checked=!!B;},style:function(A,B){A.style.cssText=B?B:"";}}};Element._attributeTranslations.has={};$w("colSpan rowSpan vAlign dateTime accessKey tabIndex encType maxLength readOnly longDesc").each(function(A){Element._attributeTranslations.write.names[A.toLowerCase()]=A;Element._attributeTranslations.has[A.toLowerCase()]=A;});(function(A){Object.extend(A,{href:A._getAttr,src:A._getAttr,type:A._getAttr,action:A._getAttrNode,disabled:A._flag,checked:A._flag,readonly:A._flag,multiple:A._flag,onload:A._getEv,onunload:A._getEv,onclick:A._getEv,ondblclick:A._getEv,onmousedown:A._getEv,onmouseup:A._getEv,onmouseover:A._getEv,onmousemove:A._getEv,onmouseout:A._getEv,onfocus:A._getEv,onblur:A._getEv,onkeypress:A._getEv,onkeydown:A._getEv,onkeyup:A._getEv,onsubmit:A._getEv,onreset:A._getEv,onselect:A._getEv,onchange:A._getEv});})(Element._attributeTranslations.read.values);}else{if(Prototype.Browser.Gecko&&/rv:1\.8\.0/.test(navigator.userAgent)){Element.Methods.setOpacity=function(A,B){A=$(A);A.style.opacity=(B==1)?0.999999:(B==="")?"":(B<0.00001)?0:B;return A;};}else{if(Prototype.Browser.WebKit){Element.Methods.setOpacity=function(A,B){A=$(A);A.style.opacity=(B==1||B==="")?"":(B<0.00001)?0:B;if(B==1){if(A.tagName=="IMG"&&A.width){A.width++;A.width--;}else{try{var D=document.createTextNode(" ");A.appendChild(D);A.removeChild(D);}catch(C){}}}return A;};Element.Methods.cumulativeOffset=function(B){var A=0,C=0;do{A+=B.offsetTop||0;C+=B.offsetLeft||0;if(B.offsetParent==document.body){if(Element.getStyle(B,"position")=="absolute"){break;}}B=B.offsetParent;}while(B);return Element._returnOffset(C,A);};}}}}if(Prototype.Browser.IE||Prototype.Browser.Opera){Element.Methods.update=function(B,C){B=$(B);if(C&&C.toElement){C=C.toElement();}if(Object.isElement(C)){return B.update().insert(C);}C=Object.toHTML(C);var A=B.tagName.toUpperCase();if(A in Element._insertionTranslations.tags){$A(B.childNodes).each(function(D){B.removeChild(D);});Element._getContentFromAnonymousElement(A,C.stripScripts()).each(function(D){B.appendChild(D);});}else{B.innerHTML=C.stripScripts();}C.evalScripts.bind(C).defer();return B;};}if(document.createElement("div").outerHTML){Element.Methods.replace=function(C,E){C=$(C);if(E&&E.toElement){E=E.toElement();}if(Object.isElement(E)){C.parentNode.replaceChild(E,C);return C;}E=Object.toHTML(E);var D=C.parentNode,B=D.tagName.toUpperCase();if(Element._insertionTranslations.tags[B]){var F=C.next();var A=Element._getContentFromAnonymousElement(B,E.stripScripts());D.removeChild(C);if(F){A.each(function(G){D.insertBefore(G,F);});}else{A.each(function(G){D.appendChild(G);});}}else{C.outerHTML=E.stripScripts();}E.evalScripts.bind(E).defer();return C;};}Element._returnOffset=function(B,C){var A=[B,C];A.left=B;A.top=C;return A;};Element._getContentFromAnonymousElement=function(C,B){var D=new Element("div"),A=Element._insertionTranslations.tags[C];D.innerHTML=A[0]+B+A[1];A[2].times(function(){D=D.firstChild;});return $A(D.childNodes);};Element._insertionTranslations={before:{adjacency:"beforeBegin",insert:function(A,B){A.parentNode.insertBefore(B,A);},initializeRange:function(B,A){A.setStartBefore(B);}},top:{adjacency:"afterBegin",insert:function(A,B){A.insertBefore(B,A.firstChild);},initializeRange:function(B,A){A.selectNodeContents(B);A.collapse(true);}},bottom:{adjacency:"beforeEnd",insert:function(A,B){A.appendChild(B);}},after:{adjacency:"afterEnd",insert:function(A,B){A.parentNode.insertBefore(B,A.nextSibling);},initializeRange:function(B,A){A.setStartAfter(B);}},tags:{TABLE:["<table>","</table>",1],TBODY:["<table><tbody>","</tbody></table>",2],TR:["<table><tbody><tr>","</tr></tbody></table>",3],TD:["<table><tbody><tr><td>","</td></tr></tbody></table>",4],SELECT:["<select>","</select>",1]}};(function(){this.bottom.initializeRange=this.top.initializeRange;Object.extend(this.tags,{THEAD:this.tags.TBODY,TFOOT:this.tags.TBODY,TH:this.tags.TD});}).call(Element._insertionTranslations);Element.Methods.Simulated={hasAttribute:function(A,C){C=Element._attributeTranslations.has[C]||C;var B=$(A).getAttributeNode(C);return B&&B.specified;}};Element.Methods.ByTag={};Object.extend(Element,Element.Methods);if(!Prototype.BrowserFeatures.ElementExtensions&&document.createElement("div").__proto__){window.HTMLElement={};window.HTMLElement.prototype=document.createElement("div").__proto__;Prototype.BrowserFeatures.ElementExtensions=true;}Element.extend=(function(){if(Prototype.BrowserFeatures.SpecificElementExtensions){return Prototype.K;}var A={},B=Element.Methods.ByTag;var C=Object.extend(function(F){if(!F||F._extendedByPrototype||F.nodeType!=1||F==window){return F;}var D=Object.clone(A),E=F.tagName,H,G;if(B[E]){Object.extend(D,B[E]);}for(H in D){G=D[H];if(Object.isFunction(G)&&!(H in F)){F[H]=G.methodize();}}F._extendedByPrototype=Prototype.emptyFunction;return F;},{refresh:function(){if(!Prototype.BrowserFeatures.ElementExtensions){Object.extend(A,Element.Methods);Object.extend(A,Element.Methods.Simulated);}}});C.refresh();return C;})();Element.hasAttribute=function(A,B){if(A.hasAttribute){return A.hasAttribute(B);}return Element.Methods.Simulated.hasAttribute(A,B);};Element.addMethods=function(C){var I=Prototype.BrowserFeatures,D=Element.Methods.ByTag;if(!C){Object.extend(Form,Form.Methods);Object.extend(Form.Element,Form.Element.Methods);Object.extend(Element.Methods.ByTag,{"FORM":Object.clone(Form.Methods),"INPUT":Object.clone(Form.Element.Methods),"SELECT":Object.clone(Form.Element.Methods),"TEXTAREA":Object.clone(Form.Element.Methods)});}if(arguments.length==2){var B=C;C=arguments[1];}if(!B){Object.extend(Element.Methods,C||{});}else{if(Object.isArray(B)){B.each(H);}else{H(B);}}function H(F){F=F.toUpperCase();if(!Element.Methods.ByTag[F]){Element.Methods.ByTag[F]={};}Object.extend(Element.Methods.ByTag[F],C);}function A(L,K,F){F=F||false;for(var N in L){var M=L[N];if(!Object.isFunction(M)){continue;}if(!F||!(N in K)){K[N]=M.methodize();}}}function E(L){var F;var K={"OPTGROUP":"OptGroup","TEXTAREA":"TextArea","P":"Paragraph","FIELDSET":"FieldSet","UL":"UList","OL":"OList","DL":"DList","DIR":"Directory","H1":"Heading","H2":"Heading","H3":"Heading","H4":"Heading","H5":"Heading","H6":"Heading","Q":"Quote","INS":"Mod","DEL":"Mod","A":"Anchor","IMG":"Image","CAPTION":"TableCaption","COL":"TableCol","COLGROUP":"TableCol","THEAD":"TableSection","TFOOT":"TableSection","TBODY":"TableSection","TR":"TableRow","TH":"TableCell","TD":"TableCell","FRAMESET":"FrameSet","IFRAME":"IFrame"};if(K[L]){F="HTML"+K[L]+"Element";}if(window[F]){return window[F];}F="HTML"+L+"Element";if(window[F]){return window[F];}F="HTML"+L.capitalize()+"Element";if(window[F]){return window[F];}window[F]={};window[F].prototype=document.createElement(L).__proto__;return window[F];}if(I.ElementExtensions){A(Element.Methods,HTMLElement.prototype);A(Element.Methods.Simulated,HTMLElement.prototype,true);}if(I.SpecificElementExtensions){for(var J in Element.Methods.ByTag){var G=E(J);if(Object.isUndefined(G)){continue;}A(D[J],G.prototype);}}Object.extend(Element,Element.Methods);delete Element.ByTag;if(Element.extend.refresh){Element.extend.refresh();}Element.cache={};};document.viewport={getDimensions:function(){var A={};$w("width height").each(function(C){var B=C.capitalize();A[C]=self["inner"+B]||(document.documentElement["client"+B]||document.body["client"+B]);});return A;},getWidth:function(){return this.getDimensions().width;},getHeight:function(){return this.getDimensions().height;},getScrollOffsets:function(){return Element._returnOffset(window.pageXOffset||document.documentElement.scrollLeft||document.body.scrollLeft,window.pageYOffset||document.documentElement.scrollTop||document.body.scrollTop);}};var Selector=Class.create({initialize:function(A){this.expression=A.strip();this.compileMatcher();},compileMatcher:function(){if(Prototype.BrowserFeatures.XPath&&!(/(\[[\w-]*?:|:checked)/).test(this.expression)){return this.compileXPathMatcher();}var e=this.expression,ps=Selector.patterns,h=Selector.handlers,c=Selector.criteria,le,p,m;if(Selector._cache[e]){this.matcher=Selector._cache[e];return ;}this.matcher=["this.matcher = function(root) {","var r = root, h = Selector.handlers, c = false, n;"];while(e&&le!=e&&(/\S/).test(e)){le=e;for(var i in ps){p=ps[i];if(m=e.match(p)){this.matcher.push(Object.isFunction(c[i])?c[i](m):new Template(c[i]).evaluate(m));e=e.replace(m[0],"");break;}}}this.matcher.push("return h.unique(n);\n}");eval(this.matcher.join("\n"));Selector._cache[this.expression]=this.matcher;},compileXPathMatcher:function(){var E=this.expression,F=Selector.patterns,B=Selector.xpath,D,A;if(Selector._cache[E]){this.xpath=Selector._cache[E];return ;}this.matcher=[".//*"];while(E&&D!=E&&(/\S/).test(E)){D=E;for(var C in F){if(A=E.match(F[C])){this.matcher.push(Object.isFunction(B[C])?B[C](A):new Template(B[C]).evaluate(A));E=E.replace(A[0],"");break;}}}this.xpath=this.matcher.join("");Selector._cache[this.expression]=this.xpath;},findElements:function(A){A=A||document;if(this.xpath){return document._getElementsByXPath(this.xpath,A);}return this.matcher(A);},match:function(H){this.tokens=[];var L=this.expression,A=Selector.patterns,E=Selector.assertions;var B,D,F;while(L&&B!==L&&(/\S/).test(L)){B=L;for(var I in A){D=A[I];if(F=L.match(D)){if(E[I]){this.tokens.push([I,Object.clone(F)]);L=L.replace(F[0],"");}else{return this.findElements(document).include(H);}}}}var K=true,C,J;for(var I=0,G;G=this.tokens[I];I++){C=G[0],J=G[1];if(!Selector.assertions[C](H,J)){K=false;break;}}return K;},toString:function(){return this.expression;},inspect:function(){return"#<Selector:"+this.expression.inspect()+">";}});Object.extend(Selector,{_cache:{},xpath:{descendant:"//*",child:"/*",adjacent:"/following-sibling::*[1]",laterSibling:"/following-sibling::*",tagName:function(A){if(A[1]=="*"){return"";}return"[local-name()='"+A[1].toLowerCase()+"' or local-name()='"+A[1].toUpperCase()+"']";},className:"[contains(concat(' ', @class, ' '), ' #{1} ')]",id:"[@id='#{1}']",attrPresence:"[@#{1}]",attr:function(A){A[3]=A[5]||A[6];return new Template(Selector.xpath.operators[A[2]]).evaluate(A);},pseudo:function(A){var B=Selector.xpath.pseudos[A[1]];if(!B){return"";}if(Object.isFunction(B)){return B(A);}return new Template(Selector.xpath.pseudos[A[1]]).evaluate(A);},operators:{"=":"[@#{1}='#{3}']","!=":"[@#{1}!='#{3}']","^=":"[starts-with(@#{1}, '#{3}')]","$=":"[substring(@#{1}, (string-length(@#{1}) - string-length('#{3}') + 1))='#{3}']","*=":"[contains(@#{1}, '#{3}')]","~=":"[contains(concat(' ', @#{1}, ' '), ' #{3} ')]","|=":"[contains(concat('-', @#{1}, '-'), '-#{3}-')]"},pseudos:{"first-child":"[not(preceding-sibling::*)]","last-child":"[not(following-sibling::*)]","only-child":"[not(preceding-sibling::* or following-sibling::*)]","empty":"[count(*) = 0 and (count(text()) = 0 or translate(text(), ' \t\r\n', '') = '')]","checked":"[@checked]","disabled":"[@disabled]","enabled":"[not(@disabled)]","not":function(B){var H=B[6],G=Selector.patterns,A=Selector.xpath,E,B,C;var F=[];while(H&&E!=H&&(/\S/).test(H)){E=H;for(var D in G){if(B=H.match(G[D])){C=Object.isFunction(A[D])?A[D](B):new Template(A[D]).evaluate(B);F.push("("+C.substring(1,C.length-1)+")");H=H.replace(B[0],"");break;}}}return"[not("+F.join(" and ")+")]";},"nth-child":function(A){return Selector.xpath.pseudos.nth("(count(./preceding-sibling::*) + 1) ",A);},"nth-last-child":function(A){return Selector.xpath.pseudos.nth("(count(./following-sibling::*) + 1) ",A);},"nth-of-type":function(A){return Selector.xpath.pseudos.nth("position() ",A);},"nth-last-of-type":function(A){return Selector.xpath.pseudos.nth("(last() + 1 - position()) ",A);},"first-of-type":function(A){A[6]="1";return Selector.xpath.pseudos["nth-of-type"](A);},"last-of-type":function(A){A[6]="1";return Selector.xpath.pseudos["nth-last-of-type"](A);},"only-of-type":function(A){var B=Selector.xpath.pseudos;return B["first-of-type"](A)+B["last-of-type"](A);},nth:function(E,C){var F,G=C[6],B;if(G=="even"){G="2n+0";}if(G=="odd"){G="2n+1";}if(F=G.match(/^(\d+)$/)){return"["+E+"= "+F[1]+"]";}if(F=G.match(/^(-?\d*)?n(([+-])(\d+))?/)){if(F[1]=="-"){F[1]=-1;}var D=F[1]?Number(F[1]):1;var A=F[2]?Number(F[2]):0;B="[((#{fragment} - #{b}) mod #{a} = 0) and ((#{fragment} - #{b}) div #{a} >= 0)]";return new Template(B).evaluate({fragment:E,a:D,b:A});}}}},criteria:{tagName:'n = h.tagName(n, r, "#{1}", c);   c = false;',className:'n = h.className(n, r, "#{1}", c); c = false;',id:'n = h.id(n, r, "#{1}", c);        c = false;',attrPresence:'n = h.attrPresence(n, r, "#{1}"); c = false;',attr:function(A){A[3]=(A[5]||A[6]);return new Template('n = h.attr(n, r, "#{1}", "#{3}", "#{2}"); c = false;').evaluate(A);},pseudo:function(A){if(A[6]){A[6]=A[6].replace(/"/g,'\\"');}return new Template('n = h.pseudo(n, "#{1}", "#{6}", r, c); c = false;').evaluate(A);},descendant:'c = "descendant";',child:'c = "child";',adjacent:'c = "adjacent";',laterSibling:'c = "laterSibling";'},patterns:{laterSibling:/^\s*~\s*/,child:/^\s*>\s*/,adjacent:/^\s*\+\s*/,descendant:/^\s/,tagName:/^\s*(\*|[\w\-]+)(\b|$)?/,id:/^#([\w\-\*]+)(\b|$)/,className:/^\.([\w\-\*]+)(\b|$)/,pseudo:/^:((first|last|nth|nth-last|only)(-child|-of-type)|empty|checked|(en|dis)abled|not)(\((.*?)\))?(\b|$|(?=\s)|(?=:))/,attrPresence:/^\[([\w]+)\]/,attr:/\[((?:[\w-]*:)?[\w-]+)\s*(?:([!^$*~|]?=)\s*((['"])([^\4]*?)\4|([^'"][^\]]*?)))?\]/},assertions:{tagName:function(A,B){return B[1].toUpperCase()==A.tagName.toUpperCase();},className:function(A,B){return Element.hasClassName(A,B[1]);},id:function(A,B){return A.id===B[1];},attrPresence:function(A,B){return Element.hasAttribute(A,B[1]);},attr:function(B,C){var A=Element.readAttribute(B,C[1]);return Selector.operators[C[2]](A,C[3]);}},handlers:{concat:function(B,A){for(var C=0,D;D=A[C];C++){B.push(D);}return B;},mark:function(A){for(var B=0,C;C=A[B];B++){C._counted=true;}return A;},unmark:function(A){for(var B=0,C;C=A[B];B++){C._counted=undefined;}return A;},index:function(A,D,G){A._counted=true;if(D){for(var B=A.childNodes,E=B.length-1,C=1;E>=0;E--){var F=B[E];if(F.nodeType==1&&(!G||F._counted)){F.nodeIndex=C++;}}}else{for(var E=0,C=1,B=A.childNodes;F=B[E];E++){if(F.nodeType==1&&(!G||F._counted)){F.nodeIndex=C++;}}}},unique:function(B){if(B.length==0){return B;}var D=[],E;for(var C=0,A=B.length;C<A;C++){if(!(E=B[C])._counted){E._counted=true;D.push(Element.extend(E));}}return Selector.handlers.unmark(D);},descendant:function(A){var D=Selector.handlers;for(var C=0,B=[],E;E=A[C];C++){D.concat(B,E.getElementsByTagName("*"));}return B;},child:function(A){var F=Selector.handlers;for(var E=0,D=[],G;G=A[E];E++){for(var B=0,C=[],H;H=G.childNodes[B];B++){if(H.nodeType==1&&H.tagName!="!"){D.push(H);}}}return D;},adjacent:function(A){for(var C=0,B=[],E;E=A[C];C++){var D=this.nextElementSibling(E);if(D){B.push(D);}}return B;},laterSibling:function(A){var D=Selector.handlers;for(var C=0,B=[],E;E=A[C];C++){D.concat(B,Element.nextSiblings(E));}return B;},nextElementSibling:function(A){while(A=A.nextSibling){if(A.nodeType==1){return A;}}return null;},previousElementSibling:function(A){while(A=A.previousSibling){if(A.nodeType==1){return A;}}return null;},tagName:function(B,A,E,H){E=E.toUpperCase();var D=[],F=Selector.handlers;if(B){if(H){if(H=="descendant"){for(var C=0,G;G=B[C];C++){F.concat(D,G.getElementsByTagName(E));}return D;}else{B=this[H](B);}if(E=="*"){return B;}}for(var C=0,G;G=B[C];C++){if(G.tagName.toUpperCase()==E){D.push(G);}}return D;}else{return A.getElementsByTagName(E);}},id:function(B,A,H,F){var G=$(H),D=Selector.handlers;if(!G){return[];}if(!B&&A==document){return[G];}if(B){if(F){if(F=="child"){for(var C=0,E;E=B[C];C++){if(G.parentNode==E){return[G];}}}else{if(F=="descendant"){for(var C=0,E;E=B[C];C++){if(Element.descendantOf(G,E)){return[G];}}}else{if(F=="adjacent"){for(var C=0,E;E=B[C];C++){if(Selector.handlers.previousElementSibling(G)==E){return[G];}}}else{B=D[F](B);}}}}for(var C=0,E;E=B[C];C++){if(E==G){return[G];}}return[];}return(G&&Element.descendantOf(G,A))?[G]:[];},className:function(B,A,C,D){if(B&&D){B=this[D](B);}return Selector.handlers.byClassName(B,A,C);},byClassName:function(C,B,F){if(!C){C=Selector.handlers.descendant([B]);}var H=" "+F+" ";for(var E=0,D=[],G,A;G=C[E];E++){A=G.className;if(A.length==0){continue;}if(A==F||(" "+A+" ").include(H)){D.push(G);}}return D;},attrPresence:function(C,B,A){if(!C){C=B.getElementsByTagName("*");}var E=[];for(var D=0,F;F=C[D];D++){if(Element.hasAttribute(F,A)){E.push(F);}}return E;},attr:function(A,H,G,I,B){if(!A){A=H.getElementsByTagName("*");}var J=Selector.operators[B],D=[];for(var E=0,C;C=A[E];E++){var F=Element.readAttribute(C,G);if(F===null){continue;}if(J(F,I)){D.push(C);}}return D;},pseudo:function(B,C,E,A,D){if(B&&D){B=this[D](B);}if(!B){B=A.getElementsByTagName("*");}return Selector.pseudos[C](B,E,A);}},pseudos:{"first-child":function(B,F,A){for(var D=0,C=[],E;E=B[D];D++){if(Selector.handlers.previousElementSibling(E)){continue;}C.push(E);}return C;},"last-child":function(B,F,A){for(var D=0,C=[],E;E=B[D];D++){if(Selector.handlers.nextElementSibling(E)){continue;}C.push(E);}return C;},"only-child":function(B,G,A){var E=Selector.handlers;for(var D=0,C=[],F;F=B[D];D++){if(!E.previousElementSibling(F)&&!E.nextElementSibling(F)){C.push(F);}}return C;},"nth-child":function(B,C,A){return Selector.pseudos.nth(B,C,A);},"nth-last-child":function(B,C,A){return Selector.pseudos.nth(B,C,A,true);},"nth-of-type":function(B,C,A){return Selector.pseudos.nth(B,C,A,false,true);},"nth-last-of-type":function(B,C,A){return Selector.pseudos.nth(B,C,A,true,true);},"first-of-type":function(B,C,A){return Selector.pseudos.nth(B,"1",A,false,true);},"last-of-type":function(B,C,A){return Selector.pseudos.nth(B,"1",A,true,true);},"only-of-type":function(B,D,A){var C=Selector.pseudos;return C["last-of-type"](C["first-of-type"](B,D,A),D,A);},getIndices:function(B,A,C){if(B==0){return A>0?[A]:[];}return $R(1,C).inject([],function(D,E){if(0==(E-A)%B&&(E-A)/B>=0){D.push(E);}return D;});},nth:function(A,L,N,K,C){if(A.length==0){return[];}if(L=="even"){L="2n+0";}if(L=="odd"){L="2n+1";}var J=Selector.handlers,I=[],B=[],E;J.mark(A);for(var H=0,D;D=A[H];H++){if(!D.parentNode._counted){J.index(D.parentNode,K,C);B.push(D.parentNode);}}if(L.match(/^\d+$/)){L=Number(L);for(var H=0,D;D=A[H];H++){if(D.nodeIndex==L){I.push(D);}}}else{if(E=L.match(/^(-?\d*)?n(([+-])(\d+))?/)){if(E[1]=="-"){E[1]=-1;}var O=E[1]?Number(E[1]):1;var M=E[2]?Number(E[2]):0;var P=Selector.pseudos.getIndices(O,M,A.length);for(var H=0,D,F=P.length;D=A[H];H++){for(var G=0;G<F;G++){if(D.nodeIndex==P[G]){I.push(D);}}}}}J.unmark(A);J.unmark(B);return I;},"empty":function(B,F,A){for(var D=0,C=[],E;E=B[D];D++){if(E.tagName=="!"||(E.firstChild&&!E.innerHTML.match(/^\s*$/))){continue;}C.push(E);}return C;},"not":function(A,D,I){var G=Selector.handlers,J,C;var H=new Selector(D).findElements(I);G.mark(H);for(var F=0,E=[],B;B=A[F];F++){if(!B._counted){E.push(B);}}G.unmark(H);return E;},"enabled":function(B,F,A){for(var D=0,C=[],E;E=B[D];D++){if(!E.disabled){C.push(E);}}return C;},"disabled":function(B,F,A){for(var D=0,C=[],E;E=B[D];D++){if(E.disabled){C.push(E);}}return C;},"checked":function(B,F,A){for(var D=0,C=[],E;E=B[D];D++){if(E.checked){C.push(E);}}return C;}},operators:{"=":function(B,A){return B==A;},"!=":function(B,A){return B!=A;},"^=":function(B,A){return B.startsWith(A);},"$=":function(B,A){return B.endsWith(A);},"*=":function(B,A){return B.include(A);},"~=":function(B,A){return(" "+B+" ").include(" "+A+" ");},"|=":function(B,A){return("-"+B.toUpperCase()+"-").include("-"+A.toUpperCase()+"-");}},matchElements:function(F,G){var E=new Selector(G).findElements(),D=Selector.handlers;D.mark(E);for(var C=0,B=[],A;A=F[C];C++){if(A._counted){B.push(A);}}D.unmark(E);return B;},findElement:function(B,C,A){if(Object.isNumber(C)){A=C;C=false;}return Selector.matchElements(B,C||"*")[A||0];},findChildElements:function(E,G){var H=G.join(","),G=[];H.scan(/(([\w#:.~>+()\s-]+|\*|\[.*?\])+)\s*(,|$)/,function(I){G.push(I[1].strip());});var D=[],F=Selector.handlers;for(var C=0,B=G.length,A;C<B;C++){A=new Selector(G[C].strip());F.concat(D,A.findElements(E));}return(B>1)?F.unique(D):D;}});function $$(){return Selector.findChildElements(document,$A(arguments));}var Form={reset:function(A){$(A).reset();return A;},serializeElements:function(G,B){if(typeof B!="object"){B={hash:!!B};}else{if(B.hash===undefined){B.hash=true;}}var C,F,A=false,E=B.submit;var D=G.inject({},function(H,I){if(!I.disabled&&I.name){C=I.name;F=$(I).getValue();if(F!=null&&(I.type!="submit"||(!A&&E!==false&&(!E||C==E)&&(A=true)))){if(C in H){if(!Object.isArray(H[C])){H[C]=[H[C]];}H[C].push(F);}else{H[C]=F;}}}return H;});return B.hash?D:Object.toQueryString(D);}};Form.Methods={serialize:function(B,A){return Form.serializeElements(Form.getElements(B),A);},getElements:function(A){return $A($(A).getElementsByTagName("*")).inject([],function(B,C){if(Form.Element.Serializers[C.tagName.toLowerCase()]){B.push(Element.extend(C));}return B;});},getInputs:function(G,C,D){G=$(G);var A=G.getElementsByTagName("input");if(!C&&!D){return $A(A).map(Element.extend);}for(var E=0,H=[],F=A.length;E<F;E++){var B=A[E];if((C&&B.type!=C)||(D&&B.name!=D)){continue;}H.push(Element.extend(B));}return H;},disable:function(A){A=$(A);Form.getElements(A).invoke("disable");return A;},enable:function(A){A=$(A);Form.getElements(A).invoke("enable");return A;},findFirstElement:function(B){var C=$(B).getElements().findAll(function(D){return"hidden"!=D.type&&!D.disabled;});var A=C.findAll(function(D){return D.hasAttribute("tabIndex")&&D.tabIndex>=0;}).sortBy(function(D){return D.tabIndex;}).first();return A?A:C.find(function(D){return["input","select","textarea"].include(D.tagName.toLowerCase());});},focusFirstElement:function(A){A=$(A);A.findFirstElement().activate();return A;},request:function(B,A){B=$(B),A=Object.clone(A||{});var D=A.parameters,C=B.readAttribute("action")||"";if(C.blank()){C=window.location.href;}A.parameters=B.serialize(true);if(D){if(Object.isString(D)){D=D.toQueryParams();}Object.extend(A.parameters,D);}if(B.hasAttribute("method")&&!A.method){A.method=B.method;}return new Ajax.Request(C,A);}};Form.Element={focus:function(A){$(A).focus();return A;},select:function(A){$(A).select();return A;}};Form.Element.Methods={serialize:function(A){A=$(A);if(!A.disabled&&A.name){var B=A.getValue();if(B!=undefined){var C={};C[A.name]=B;return Object.toQueryString(C);}}return"";},getValue:function(A){A=$(A);var B=A.tagName.toLowerCase();return Form.Element.Serializers[B](A);},setValue:function(A,B){A=$(A);var C=A.tagName.toLowerCase();Form.Element.Serializers[C](A,B);return A;},clear:function(A){$(A).value="";return A;},present:function(A){return $(A).value!="";},activate:function(A){A=$(A);try{A.focus();if(A.select&&(A.tagName.toLowerCase()!="input"||!["button","reset","submit"].include(A.type))){A.select();}}catch(B){}return A;},disable:function(A){A=$(A);A.blur();A.disabled=true;return A;},enable:function(A){A=$(A);A.disabled=false;return A;}};var Field=Form.Element;var $F=Form.Element.Methods.getValue;Form.Element.Serializers={input:function(A,B){switch(A.type.toLowerCase()){case"checkbox":case"radio":return Form.Element.Serializers.inputSelector(A,B);default:return Form.Element.Serializers.textarea(A,B);}},inputSelector:function(A,B){if(B===undefined){return A.checked?A.value:null;}else{A.checked=!!B;}},textarea:function(A,B){if(B===undefined){return A.value;}else{A.value=B;}},select:function(D,A){if(A===undefined){return this[D.type=="select-one"?"selectOne":"selectMany"](D);}else{var C,F,G=!Object.isArray(A);for(var B=0,E=D.length;B<E;B++){C=D.options[B];F=this.optionValue(C);if(G){if(F==A){C.selected=true;return ;}}else{C.selected=A.include(F);}}}},selectOne:function(B){var A=B.selectedIndex;return A>=0?this.optionValue(B.options[A]):null;},selectMany:function(D){var A,E=D.length;if(!E){return null;}for(var C=0,A=[];C<E;C++){var B=D.options[C];if(B.selected){A.push(this.optionValue(B));}}return A;},optionValue:function(A){return Element.extend(A).hasAttribute("value")?A.value:A.text;}};Abstract.TimedObserver=Class.create(PeriodicalExecuter,{initialize:function($super,A,B,C){$super(C,B);this.element=$(A);this.lastValue=this.getValue();},execute:function(){var A=this.getValue();if(Object.isString(this.lastValue)&&Object.isString(A)?this.lastValue!=A:String(this.lastValue)!=String(A)){this.callback(this.element,A);this.lastValue=A;}}});Form.Element.Observer=Class.create(Abstract.TimedObserver,{getValue:function(){return Form.Element.getValue(this.element);}});Form.Observer=Class.create(Abstract.TimedObserver,{getValue:function(){return Form.serialize(this.element);}});Abstract.EventObserver=Class.create({initialize:function(A,B){this.element=$(A);this.callback=B;this.lastValue=this.getValue();if(this.element.tagName.toLowerCase()=="form"){this.registerFormCallbacks();}else{this.registerCallback(this.element);}},onElementEvent:function(){var A=this.getValue();if(this.lastValue!=A){this.callback(this.element,A);this.lastValue=A;}},registerFormCallbacks:function(){Form.getElements(this.element).each(this.registerCallback,this);},registerCallback:function(A){if(A.type){switch(A.type.toLowerCase()){case"checkbox":case"radio":Event.observe(A,"click",this.onElementEvent.bind(this));break;default:Event.observe(A,"change",this.onElementEvent.bind(this));break;}}}});Form.Element.EventObserver=Class.create(Abstract.EventObserver,{getValue:function(){return Form.Element.getValue(this.element);}});Form.EventObserver=Class.create(Abstract.EventObserver,{getValue:function(){return Form.serialize(this.element);}});if(!window.Event){var Event={};}Object.extend(Event,{KEY_BACKSPACE:8,KEY_TAB:9,KEY_RETURN:13,KEY_ESC:27,KEY_LEFT:37,KEY_UP:38,KEY_RIGHT:39,KEY_DOWN:40,KEY_DELETE:46,KEY_HOME:36,KEY_END:35,KEY_PAGEUP:33,KEY_PAGEDOWN:34,KEY_INSERT:45,cache:{},relatedTarget:function(B){var A;switch(B.type){case"mouseover":A=B.fromElement;break;case"mouseout":A=B.toElement;break;default:return null;}return Element.extend(A);}});Event.Methods=(function(){var A;if(Prototype.Browser.IE){var B={0:1,1:4,2:2};A=function(D,C){return D.button==B[C];};}else{if(Prototype.Browser.WebKit){A=function(D,C){switch(C){case 0:return D.which==1&&!D.metaKey;case 1:return D.which==1&&D.metaKey;default:return false;}};}else{A=function(D,C){return D.which?(D.which===C+1):(D.button===C);};}}return{isLeftClick:function(C){return A(C,0);},isMiddleClick:function(C){return A(C,1);},isRightClick:function(C){return A(C,2);},element:function(D){var C=Event.extend(D).target;return Element.extend(C.nodeType==Node.TEXT_NODE?C.parentNode:C);},findElement:function(D,E){var C=Event.element(D);return C.match(E)?C:C.up(E);},pointer:function(C){return{x:C.pageX||(C.clientX+(document.documentElement.scrollLeft||document.body.scrollLeft)),y:C.pageY||(C.clientY+(document.documentElement.scrollTop||document.body.scrollTop))};},pointerX:function(C){return Event.pointer(C).x;},pointerY:function(C){return Event.pointer(C).y;},stop:function(C){Event.extend(C);C.preventDefault();C.stopPropagation();C.stopped=true;}};})();Event.extend=(function(){var A=Object.keys(Event.Methods).inject({},function(B,C){B[C]=Event.Methods[C].methodize();return B;});if(Prototype.Browser.IE){Object.extend(A,{stopPropagation:function(){this.cancelBubble=true;},preventDefault:function(){this.returnValue=false;},inspect:function(){return"[object Event]";}});return function(B){if(!B){return false;}if(B._extendedByPrototype){return B;}B._extendedByPrototype=Prototype.emptyFunction;var C=Event.pointer(B);Object.extend(B,{target:B.srcElement,relatedTarget:Event.relatedTarget(B),pageX:C.x,pageY:C.y});return Object.extend(B,A);};}else{Event.prototype=Event.prototype||document.createEvent("HTMLEvents").__proto__;Object.extend(Event.prototype,A);return Prototype.K;}})();Object.extend(Event,(function(){var B=Event.cache;function C(J){if(J._eventID){return J._eventID;}arguments.callee.id=arguments.callee.id||1;return J._eventID=++arguments.callee.id;}function G(J){if(J&&J.include(":")){return"dataavailable";}return J;}function A(J){return B[J]=B[J]||{};}function F(L,J){var K=A(L);return K[J]=K[J]||[];}function H(K,J,L){var O=C(K);var N=F(O,J);if(N.pluck("handler").include(L)){return false;}var M=function(P){if(!Event||!Event.extend||(P.eventName&&P.eventName!=J)){return false;}Event.extend(P);L.call(K,P);};M.handler=L;N.push(M);return M;}function I(M,J,K){var L=F(M,J);return L.find(function(N){return N.handler==K;});}function D(M,J,K){var L=A(M);if(!L[J]){return false;}L[J]=L[J].without(I(M,J,K));}function E(){for(var K in B){for(var J in B[K]){B[K][J]=null;}}}if(window.attachEvent){window.attachEvent("onunload",E);}return{observe:function(L,J,M){L=$(L);var K=G(J);var N=H(L,J,M);if(!N){return L;}if(L.addEventListener){L.addEventListener(K,N,false);}else{L.attachEvent("on"+K,N);}return L;},stopObserving:function(L,J,M){L=$(L);var O=C(L),K=G(J);if(!M&&J){F(O,J).each(function(P){L.stopObserving(J,P.handler);});return L;}else{if(!J){Object.keys(A(O)).each(function(P){L.stopObserving(P);});return L;}}var N=I(O,J,M);if(!N){return L;}if(L.removeEventListener){L.removeEventListener(K,N,false);}else{L.detachEvent("on"+K,N);}D(O,J,M);return L;},fire:function(L,K,J){L=$(L);if(L==document&&document.createEvent&&!L.dispatchEvent){L=document.documentElement;}if(document.createEvent){var M=document.createEvent("HTMLEvents");M.initEvent("dataavailable",true,true);}else{var M=document.createEventObject();M.eventType="ondataavailable";}M.eventName=K;M.memo=J||{};if(document.createEvent){L.dispatchEvent(M);}else{L.fireEvent(M.eventType,M);}return M;}};})());Object.extend(Event,Event.Methods);Element.addMethods({fire:Event.fire,observe:Event.observe,stopObserving:Event.stopObserving});Object.extend(document,{fire:Element.Methods.fire.methodize(),observe:Element.Methods.observe.methodize(),stopObserving:Element.Methods.stopObserving.methodize()});(function(){var C,B=false;function A(){if(B){return ;}if(C){window.clearInterval(C);}document.fire("dom:loaded");B=true;}if(document.addEventListener){if(Prototype.Browser.WebKit){C=window.setInterval(function(){if(/loaded|complete/.test(document.readyState)){A();}},0);Event.observe(window,"load",A);}else{document.addEventListener("DOMContentLoaded",A,false);}}else{document.write("<script id=__onDOMContentLoaded defer src=//:><\/script>");$("__onDOMContentLoaded").onreadystatechange=function(){if(this.readyState=="complete"){this.onreadystatechange=null;A();}};}})();Hash.toQueryString=Object.toQueryString;var Toggle={display:Element.toggle};Element.Methods.childOf=Element.Methods.descendantOf;var Insertion={Before:function(A,B){return Element.insert(A,{before:B});},Top:function(A,B){return Element.insert(A,{top:B});},Bottom:function(A,B){return Element.insert(A,{bottom:B});},After:function(A,B){return Element.insert(A,{after:B});}};var $continue=new Error('"throw $continue" is deprecated, use "return" instead');var Position={includeScrollOffsets:false,prepare:function(){this.deltaX=window.pageXOffset||document.documentElement.scrollLeft||document.body.scrollLeft||0;this.deltaY=window.pageYOffset||document.documentElement.scrollTop||document.body.scrollTop||0;},within:function(B,A,C){if(this.includeScrollOffsets){return this.withinIncludingScrolloffsets(B,A,C);}this.xcomp=A;this.ycomp=C;this.offset=Element.cumulativeOffset(B);return(C>=this.offset[1]&&C<this.offset[1]+B.offsetHeight&&A>=this.offset[0]&&A<this.offset[0]+B.offsetWidth);},withinIncludingScrolloffsets:function(B,A,D){var C=Element.cumulativeScrollOffset(B);this.xcomp=A+C[0]-this.deltaX;this.ycomp=D+C[1]-this.deltaY;this.offset=Element.cumulativeOffset(B);return(this.ycomp>=this.offset[1]&&this.ycomp<this.offset[1]+B.offsetHeight&&this.xcomp>=this.offset[0]&&this.xcomp<this.offset[0]+B.offsetWidth);},overlap:function(B,A){if(!B){return 0;}if(B=="vertical"){return((this.offset[1]+A.offsetHeight)-this.ycomp)/A.offsetHeight;}if(B=="horizontal"){return((this.offset[0]+A.offsetWidth)-this.xcomp)/A.offsetWidth;}},cumulativeOffset:Element.Methods.cumulativeOffset,positionedOffset:Element.Methods.positionedOffset,absolutize:function(A){Position.prepare();return Element.absolutize(A);},relativize:function(A){Position.prepare();return Element.relativize(A);},realOffset:Element.Methods.cumulativeScrollOffset,offsetParent:Element.Methods.getOffsetParent,page:Element.Methods.viewportOffset,clone:function(B,C,A){A=A||{};return Element.clonePosition(C,B,A);}};if(!document.getElementsByClassName){document.getElementsByClassName=function(B){function A(C){return C.blank()?null:"[contains(concat(' ', @class, ' '), ' "+C+" ')]";}B.getElementsByClassName=Prototype.BrowserFeatures.XPath?function(C,E){E=E.toString().strip();var D=/\s/.test(E)?$w(E).map(A).join(""):A(E);return D?document._getElementsByXPath(".//*"+D,C):[];}:function(E,F){F=F.toString().strip();var G=[],H=(/\s/.test(F)?$w(F):null);if(!H&&!F){return G;}var C=$(E).getElementsByTagName("*");F=" "+F+" ";for(var D=0,J,I;J=C[D];D++){if(J.className&&(I=" "+J.className+" ")&&(I.include(F)||(H&&H.all(function(K){return !K.toString().blank()&&I.include(" "+K+" ");})))){G.push(Element.extend(J));}}return G;};return function(D,C){return $(C||document.body).getElementsByClassName(D);};}(Element.Methods);}Element.ClassNames=Class.create();Element.ClassNames.prototype={initialize:function(A){this.element=$(A);},_each:function(A){this.element.className.split(/\s+/).select(function(B){return B.length>0;})._each(A);},set:function(A){this.element.className=A;},add:function(A){if(this.include(A)){return ;}this.set($A(this).concat(A).join(" "));},remove:function(A){if(!this.include(A)){return ;}this.set($A(this).without(A).join(" "));},toString:function(){return $A(this).join(" ");}};Object.extend(Element.ClassNames.prototype,Enumerable);Element.addMethods();


// Copyright (c) 2005-2008 Thomas Fuchs (http://script.aculo.us, http://mir.aculo.us)
// Contributors:
//  Justin Palmer (http://encytemedia.com/)
//  Mark Pilgrim (http://diveintomark.org/)
//  Martin Bialasinki
// 
// script.aculo.us is freely distributable under the terms of an MIT-style license.
// For details, see the script.aculo.us web site: http://script.aculo.us/ 

// converts rgb() and #xxx to #xxxxxx format,  
// returns self (or first argument) if not convertable  
String.prototype.parseColor = function() {  
  var color = '#';
  if (this.slice(0,4) == 'rgb(') {  
    var cols = this.slice(4,this.length-1).split(',');  
    var i=0; do { color += parseInt(cols[i]).toColorPart() } while (++i<3);  
  } else {  
    if (this.slice(0,1) == '#') {  
      if (this.length==4) for(var i=1;i<4;i++) color += (this.charAt(i) + this.charAt(i)).toLowerCase();  
      if (this.length==7) color = this.toLowerCase();  
    }  
  }  
  return (color.length==7 ? color : (arguments[0] || this));  
};

/*--------------------------------------------------------------------------*/

Element.collectTextNodes = function(element) {  
  return $A($(element).childNodes).collect( function(node) {
    return (node.nodeType==3 ? node.nodeValue : 
      (node.hasChildNodes() ? Element.collectTextNodes(node) : ''));
  }).flatten().join('');
};

Element.collectTextNodesIgnoreClass = function(element, className) {  
  return $A($(element).childNodes).collect( function(node) {
    return (node.nodeType==3 ? node.nodeValue : 
      ((node.hasChildNodes() && !Element.hasClassName(node,className)) ? 
        Element.collectTextNodesIgnoreClass(node, className) : ''));
  }).flatten().join('');
};

Element.setContentZoom = function(element, percent) {
  element = $(element);  
  element.setStyle({fontSize: (percent/100) + 'em'});   
  if (Prototype.Browser.WebKit) window.scrollBy(0,0);
  return element;
};

Element.getInlineOpacity = function(element){
  return $(element).style.opacity || '';
};

Element.forceRerendering = function(element) {
  try {
    element = $(element);
    var n = document.createTextNode(' ');
    element.appendChild(n);
    element.removeChild(n);
  } catch(e) { }
};

/*--------------------------------------------------------------------------*/

var Effect = {
  _elementDoesNotExistError: {
    name: 'ElementDoesNotExistError',
    message: 'The specified DOM element does not exist, but is required for this effect to operate'
  },
  Transitions: {
    linear: Prototype.K,
    sinoidal: function(pos) {
      return (-Math.cos(pos*Math.PI)/2) + 0.5;
    },
    reverse: function(pos) {
      return 1-pos;
    },
    flicker: function(pos) {
      var pos = ((-Math.cos(pos*Math.PI)/4) + 0.75) + Math.random()/4;
      return pos > 1 ? 1 : pos;
    },
    wobble: function(pos) {
      return (-Math.cos(pos*Math.PI*(9*pos))/2) + 0.5;
    },
    pulse: function(pos, pulses) { 
      pulses = pulses || 5; 
      return (
        ((pos % (1/pulses)) * pulses).round() == 0 ? 
              ((pos * pulses * 2) - (pos * pulses * 2).floor()) : 
          1 - ((pos * pulses * 2) - (pos * pulses * 2).floor())
        );
    },
    spring: function(pos) { 
      return 1 - (Math.cos(pos * 4.5 * Math.PI) * Math.exp(-pos * 6)); 
    },
    none: function(pos) {
      return 0;
    },
    full: function(pos) {
      return 1;
    }
  },
  DefaultOptions: {
    duration:   1.0,   // seconds
    fps:        100,   // 100= assume 66fps max.
    sync:       false, // true for combining
    from:       0.0,
    to:         1.0,
    delay:      0.0,
    queue:      'parallel'
  },
  tagifyText: function(element) {
    var tagifyStyle = 'position:relative';
    if (Prototype.Browser.IE) tagifyStyle += ';zoom:1';
    
    element = $(element);
    $A(element.childNodes).each( function(child) {
      if (child.nodeType==3) {
        child.nodeValue.toArray().each( function(character) {
          element.insertBefore(
            new Element('span', {style: tagifyStyle}).update(
              character == ' ' ? String.fromCharCode(160) : character), 
              child);
        });
        Element.remove(child);
      }
    });
  },
  multiple: function(element, effect) {
    var elements;
    if (((typeof element == 'object') || 
        Object.isFunction(element)) && 
       (element.length))
      elements = element;
    else
      elements = $(element).childNodes;
      
    var options = Object.extend({
      speed: 0.1,
      delay: 0.0
    }, arguments[2] || { });
    var masterDelay = options.delay;

    $A(elements).each( function(element, index) {
      new effect(element, Object.extend(options, { delay: index * options.speed + masterDelay }));
    });
  },
  PAIRS: {
    'slide':  ['SlideDown','SlideUp'],
    'blind':  ['BlindDown','BlindUp'],
    'appear': ['Appear','Fade']
  },
  toggle: function(element, effect) {
    element = $(element);
    effect = (effect || 'appear').toLowerCase();
    var options = Object.extend({
      queue: { position:'end', scope:(element.id || 'global'), limit: 1 }
    }, arguments[2] || { });
    Effect[element.visible() ? 
      Effect.PAIRS[effect][1] : Effect.PAIRS[effect][0]](element, options);
  }
};

Effect.DefaultOptions.transition = Effect.Transitions.sinoidal;

/* ------------- core effects ------------- */

Effect.ScopedQueue = Class.create(Enumerable, {
  initialize: function() {
    this.effects  = [];
    this.interval = null;    
  },
  _each: function(iterator) {
    this.effects._each(iterator);
  },
  add: function(effect) {
    var timestamp = new Date().getTime();
    
    var position = Object.isString(effect.options.queue) ? 
      effect.options.queue : effect.options.queue.position;
    
    switch(position) {
      case 'front':
        // move unstarted effects after this effect  
        this.effects.findAll(function(e){ return e.state=='idle' }).each( function(e) {
            e.startOn  += effect.finishOn;
            e.finishOn += effect.finishOn;
          });
        break;
      case 'with-last':
        timestamp = this.effects.pluck('startOn').max() || timestamp;
        break;
      case 'end':
        // start effect after last queued effect has finished
        timestamp = this.effects.pluck('finishOn').max() || timestamp;
        break;
    }
    
    effect.startOn  += timestamp;
    effect.finishOn += timestamp;

    if (!effect.options.queue.limit || (this.effects.length < effect.options.queue.limit))
      this.effects.push(effect);
    
    if (!this.interval)
      this.interval = setInterval(this.loop.bind(this), 15);
  },
  remove: function(effect) {
    this.effects = this.effects.reject(function(e) { return e==effect });
    if (this.effects.length == 0) {
      clearInterval(this.interval);
      this.interval = null;
    }
  },
  loop: function() {
    var timePos = new Date().getTime();
    for(var i=0, len=this.effects.length;i<len;i++) 
      this.effects[i] && this.effects[i].loop(timePos);
  }
});

Effect.Queues = {
  instances: $H(),
  get: function(queueName) {
    if (!Object.isString(queueName)) return queueName;
    
    return this.instances.get(queueName) ||
      this.instances.set(queueName, new Effect.ScopedQueue());
  }
};
Effect.Queue = Effect.Queues.get('global');

Effect.Base = Class.create({
  position: null,
  start: function(options) {
    function codeForEvent(options,eventName){
      return (
        (options[eventName+'Internal'] ? 'this.options.'+eventName+'Internal(this);' : '') +
        (options[eventName] ? 'this.options.'+eventName+'(this);' : '')
      );
    }
    if (options && options.transition === false) options.transition = Effect.Transitions.linear;
    this.options      = Object.extend(Object.extend({ },Effect.DefaultOptions), options || { });
    this.currentFrame = 0;
    this.state        = 'idle';
    this.startOn      = this.options.delay*1000;
    this.finishOn     = this.startOn+(this.options.duration*1000);
    this.fromToDelta  = this.options.to-this.options.from;
    this.totalTime    = this.finishOn-this.startOn;
    this.totalFrames  = this.options.fps*this.options.duration;
    
    eval('this.render = function(pos){ '+
      'if (this.state=="idle"){this.state="running";'+
      codeForEvent(this.options,'beforeSetup')+
      (this.setup ? 'this.setup();':'')+ 
      codeForEvent(this.options,'afterSetup')+
      '};if (this.state=="running"){'+
      'pos=this.options.transition(pos)*'+this.fromToDelta+'+'+this.options.from+';'+
      'this.position=pos;'+
      codeForEvent(this.options,'beforeUpdate')+
      (this.update ? 'this.update(pos);':'')+
      codeForEvent(this.options,'afterUpdate')+
      '}}');
    
    this.event('beforeStart');
    if (!this.options.sync)
      Effect.Queues.get(Object.isString(this.options.queue) ? 
        'global' : this.options.queue.scope).add(this);
  },
  loop: function(timePos) {
    if (timePos >= this.startOn) {
      if (timePos >= this.finishOn) {
        this.render(1.0);
        this.cancel();
        this.event('beforeFinish');
        if (this.finish) this.finish(); 
        this.event('afterFinish');
        return;  
      }
      var pos   = (timePos - this.startOn) / this.totalTime,
          frame = (pos * this.totalFrames).round();
      if (frame > this.currentFrame) {
        this.render(pos);
        this.currentFrame = frame;
      }
    }
  },
  cancel: function() {
    if (!this.options.sync)
      Effect.Queues.get(Object.isString(this.options.queue) ? 
        'global' : this.options.queue.scope).remove(this);
    this.state = 'finished';
  },
  event: function(eventName) {
    if (this.options[eventName + 'Internal']) this.options[eventName + 'Internal'](this);
    if (this.options[eventName]) this.options[eventName](this);
  },
  inspect: function() {
    var data = $H();
    for(property in this)
      if (!Object.isFunction(this[property])) data.set(property, this[property]);
    return '#<Effect:' + data.inspect() + ',options:' + $H(this.options).inspect() + '>';
  }
});

Effect.Parallel = Class.create(Effect.Base, {
  initialize: function(effects) {
    this.effects = effects || [];
    this.start(arguments[1]);
  },
  update: function(position) {
    this.effects.invoke('render', position);
  },
  finish: function(position) {
    this.effects.each( function(effect) {
      effect.render(1.0);
      effect.cancel();
      effect.event('beforeFinish');
      if (effect.finish) effect.finish(position);
      effect.event('afterFinish');
    });
  }
});

Effect.Tween = Class.create(Effect.Base, {
  initialize: function(object, from, to) {
    object = Object.isString(object) ? $(object) : object;
    var args = $A(arguments), method = args.last(), 
      options = args.length == 5 ? args[3] : null;
    this.method = Object.isFunction(method) ? method.bind(object) :
      Object.isFunction(object[method]) ? object[method].bind(object) : 
      function(value) { object[method] = value };
    this.start(Object.extend({ from: from, to: to }, options || { }));
  },
  update: function(position) {
    this.method(position);
  }
});

Effect.Event = Class.create(Effect.Base, {
  initialize: function() {
    this.start(Object.extend({ duration: 0 }, arguments[0] || { }));
  },
  update: Prototype.emptyFunction
});

Effect.Opacity = Class.create(Effect.Base, {
  initialize: function(element) {
    this.element = $(element);
    if (!this.element) throw(Effect._elementDoesNotExistError);
    // make this work on IE on elements without 'layout'
    if (Prototype.Browser.IE && (!this.element.currentStyle.hasLayout))
      this.element.setStyle({zoom: 1});
    var options = Object.extend({
      from: this.element.getOpacity() || 0.0,
      to:   1.0
    }, arguments[1] || { });
    this.start(options);
  },
  update: function(position) {
    this.element.setOpacity(position);
  }
});

Effect.Move = Class.create(Effect.Base, {
  initialize: function(element) {
    this.element = $(element);
    if (!this.element) throw(Effect._elementDoesNotExistError);
    var options = Object.extend({
      x:    0,
      y:    0,
      mode: 'relative'
    }, arguments[1] || { });
    this.start(options);
  },
  setup: function() {
    this.element.makePositioned();
    this.originalLeft = parseFloat(this.element.getStyle('left') || '0');
    this.originalTop  = parseFloat(this.element.getStyle('top')  || '0');
    if (this.options.mode == 'absolute') {
      this.options.x = this.options.x - this.originalLeft;
      this.options.y = this.options.y - this.originalTop;
    }
  },
  update: function(position) {
    this.element.setStyle({
      left: (this.options.x  * position + this.originalLeft).round() + 'px',
      top:  (this.options.y  * position + this.originalTop).round()  + 'px'
    });
  }
});

// for backwards compatibility
Effect.MoveBy = function(element, toTop, toLeft) {
  return new Effect.Move(element, 
    Object.extend({ x: toLeft, y: toTop }, arguments[3] || { }));
};

Effect.Scale = Class.create(Effect.Base, {
  initialize: function(element, percent) {
    this.element = $(element);
    if (!this.element) throw(Effect._elementDoesNotExistError);
    var options = Object.extend({
      scaleX: true,
      scaleY: true,
      scaleContent: true,
      scaleFromCenter: false,
      scaleMode: 'box',        // 'box' or 'contents' or { } with provided values
      scaleFrom: 100.0,
      scaleTo:   percent
    }, arguments[2] || { });
    this.start(options);
  },
  setup: function() {
    this.restoreAfterFinish = this.options.restoreAfterFinish || false;
    this.elementPositioning = this.element.getStyle('position');
    
    this.originalStyle = { };
    ['top','left','width','height','fontSize'].each( function(k) {
      this.originalStyle[k] = this.element.style[k];
    }.bind(this));
      
    this.originalTop  = this.element.offsetTop;
    this.originalLeft = this.element.offsetLeft;
    
    var fontSize = this.element.getStyle('font-size') || '100%';
    ['em','px','%','pt'].each( function(fontSizeType) {
      if (fontSize.indexOf(fontSizeType)>0) {
        this.fontSize     = parseFloat(fontSize);
        this.fontSizeType = fontSizeType;
      }
    }.bind(this));
    
    this.factor = (this.options.scaleTo - this.options.scaleFrom)/100;
    
    this.dims = null;
    if (this.options.scaleMode=='box')
      this.dims = [this.element.offsetHeight, this.element.offsetWidth];
    if (/^content/.test(this.options.scaleMode))
      this.dims = [this.element.scrollHeight, this.element.scrollWidth];
    if (!this.dims)
      this.dims = [this.options.scaleMode.originalHeight,
                   this.options.scaleMode.originalWidth];
  },
  update: function(position) {
    var currentScale = (this.options.scaleFrom/100.0) + (this.factor * position);
    if (this.options.scaleContent && this.fontSize)
      this.element.setStyle({fontSize: this.fontSize * currentScale + this.fontSizeType });
    this.setDimensions(this.dims[0] * currentScale, this.dims[1] * currentScale);
  },
  finish: function(position) {
    if (this.restoreAfterFinish) this.element.setStyle(this.originalStyle);
  },
  setDimensions: function(height, width) {
    var d = { };
    if (this.options.scaleX) d.width = width.round() + 'px';
    if (this.options.scaleY) d.height = height.round() + 'px';
    if (this.options.scaleFromCenter) {
      var topd  = (height - this.dims[0])/2;
      var leftd = (width  - this.dims[1])/2;
      if (this.elementPositioning == 'absolute') {
        if (this.options.scaleY) d.top = this.originalTop-topd + 'px';
        if (this.options.scaleX) d.left = this.originalLeft-leftd + 'px';
      } else {
        if (this.options.scaleY) d.top = -topd + 'px';
        if (this.options.scaleX) d.left = -leftd + 'px';
      }
    }
    this.element.setStyle(d);
  }
});

Effect.Highlight = Class.create(Effect.Base, {
  initialize: function(element) {
    this.element = $(element);
    if (!this.element) throw(Effect._elementDoesNotExistError);
    var options = Object.extend({ startcolor: '#ffff99' }, arguments[1] || { });
    this.start(options);
  },
  setup: function() {
    // Prevent executing on elements not in the layout flow
    if (this.element.getStyle('display')=='none') { this.cancel(); return; }
    // Disable background image during the effect
    this.oldStyle = { };
    if (!this.options.keepBackgroundImage) {
      this.oldStyle.backgroundImage = this.element.getStyle('background-image');
      this.element.setStyle({backgroundImage: 'none'});
    }
    if (!this.options.endcolor)
      this.options.endcolor = this.element.getStyle('background-color').parseColor('#ffffff');
    if (!this.options.restorecolor)
      this.options.restorecolor = this.element.getStyle('background-color');
    // init color calculations
    this._base  = $R(0,2).map(function(i){ return parseInt(this.options.startcolor.slice(i*2+1,i*2+3),16) }.bind(this));
    this._delta = $R(0,2).map(function(i){ return parseInt(this.options.endcolor.slice(i*2+1,i*2+3),16)-this._base[i] }.bind(this));
  },
  update: function(position) {
    this.element.setStyle({backgroundColor: $R(0,2).inject('#',function(m,v,i){
      return m+((this._base[i]+(this._delta[i]*position)).round().toColorPart()); }.bind(this)) });
  },
  finish: function() {
    this.element.setStyle(Object.extend(this.oldStyle, {
      backgroundColor: this.options.restorecolor
    }));
  }
});

Effect.ScrollTo = function(element) {
  var options = arguments[1] || { },
    scrollOffsets = document.viewport.getScrollOffsets(),
    elementOffsets = $(element).cumulativeOffset(),
    max = (window.height || document.body.scrollHeight) - document.viewport.getHeight();  

  if (options.offset) elementOffsets[1] += options.offset;

  return new Effect.Tween(null,
    scrollOffsets.top,
    elementOffsets[1] > max ? max : elementOffsets[1],
    options,
    function(p){ scrollTo(scrollOffsets.left, p.round()) }
  );
};

/* ------------- combination effects ------------- */

Effect.Fade = function(element) {
  element = $(element);
  var oldOpacity = element.getInlineOpacity();
  var options = Object.extend({
    from: element.getOpacity() || 1.0,
    to:   0.0,
    afterFinishInternal: function(effect) { 
      if (effect.options.to!=0) return;
      effect.element.hide().setStyle({opacity: oldOpacity}); 
    }
  }, arguments[1] || { });
  return new Effect.Opacity(element,options);
};

Effect.Appear = function(element) {
  element = $(element);
  var options = Object.extend({
  from: (element.getStyle('display') == 'none' ? 0.0 : element.getOpacity() || 0.0),
  to:   1.0,
  // force Safari to render floated elements properly
  afterFinishInternal: function(effect) {
    effect.element.forceRerendering();
  },
  beforeSetup: function(effect) {
    effect.element.setOpacity(effect.options.from).show(); 
  }}, arguments[1] || { });
  return new Effect.Opacity(element,options);
};

Effect.Puff = function(element) {
  element = $(element);
  var oldStyle = { 
    opacity: element.getInlineOpacity(), 
    position: element.getStyle('position'),
    top:  element.style.top,
    left: element.style.left,
    width: element.style.width,
    height: element.style.height
  };
  return new Effect.Parallel(
   [ new Effect.Scale(element, 200, 
      { sync: true, scaleFromCenter: true, scaleContent: true, restoreAfterFinish: true }), 
     new Effect.Opacity(element, { sync: true, to: 0.0 } ) ], 
     Object.extend({ duration: 1.0, 
      beforeSetupInternal: function(effect) {
        Position.absolutize(effect.effects[0].element)
      },
      afterFinishInternal: function(effect) {
         effect.effects[0].element.hide().setStyle(oldStyle); }
     }, arguments[1] || { })
   );
};

Effect.BlindUp = function(element) {
  element = $(element);
  element.makeClipping();
  return new Effect.Scale(element, 0,
    Object.extend({ scaleContent: false, 
      scaleX: false, 
      restoreAfterFinish: true,
      afterFinishInternal: function(effect) {
        effect.element.hide().undoClipping();
      } 
    }, arguments[1] || { })
  );
};

Effect.BlindDown = function(element) {
  element = $(element);
  var elementDimensions = element.getDimensions();
  return new Effect.Scale(element, 100, Object.extend({ 
    scaleContent: false, 
    scaleX: false,
    scaleFrom: 0,
    scaleMode: {originalHeight: elementDimensions.height, originalWidth: elementDimensions.width},
    restoreAfterFinish: true,
    afterSetup: function(effect) {
      effect.element.makeClipping().setStyle({height: '0px'}).show(); 
    },  
    afterFinishInternal: function(effect) {
      effect.element.undoClipping();
    }
  }, arguments[1] || { }));
};

Effect.SwitchOff = function(element) {
  element = $(element);
  var oldOpacity = element.getInlineOpacity();
  return new Effect.Appear(element, Object.extend({
    duration: 0.4,
    from: 0,
    transition: Effect.Transitions.flicker,
    afterFinishInternal: function(effect) {
      new Effect.Scale(effect.element, 1, { 
        duration: 0.3, scaleFromCenter: true,
        scaleX: false, scaleContent: false, restoreAfterFinish: true,
        beforeSetup: function(effect) { 
          effect.element.makePositioned().makeClipping();
        },
        afterFinishInternal: function(effect) {
          effect.element.hide().undoClipping().undoPositioned().setStyle({opacity: oldOpacity});
        }
      })
    }
  }, arguments[1] || { }));
};

Effect.DropOut = function(element) {
  element = $(element);
  var oldStyle = {
    top: element.getStyle('top'),
    left: element.getStyle('left'),
    opacity: element.getInlineOpacity() };
  return new Effect.Parallel(
    [ new Effect.Move(element, {x: 0, y: 100, sync: true }), 
      new Effect.Opacity(element, { sync: true, to: 0.0 }) ],
    Object.extend(
      { duration: 0.5,
        beforeSetup: function(effect) {
          effect.effects[0].element.makePositioned(); 
        },
        afterFinishInternal: function(effect) {
          effect.effects[0].element.hide().undoPositioned().setStyle(oldStyle);
        } 
      }, arguments[1] || { }));
};

Effect.Shake = function(element) {
  element = $(element);
  var options = Object.extend({
    distance: 20,
    duration: 0.5
  }, arguments[1] || {});
  var distance = parseFloat(options.distance);
  var split = parseFloat(options.duration) / 10.0;
  var oldStyle = {
    top: element.getStyle('top'),
    left: element.getStyle('left') };
    return new Effect.Move(element,
      { x:  distance, y: 0, duration: split, afterFinishInternal: function(effect) {
    new Effect.Move(effect.element,
      { x: -distance*2, y: 0, duration: split*2,  afterFinishInternal: function(effect) {
    new Effect.Move(effect.element,
      { x:  distance*2, y: 0, duration: split*2,  afterFinishInternal: function(effect) {
    new Effect.Move(effect.element,
      { x: -distance*2, y: 0, duration: split*2,  afterFinishInternal: function(effect) {
    new Effect.Move(effect.element,
      { x:  distance*2, y: 0, duration: split*2,  afterFinishInternal: function(effect) {
    new Effect.Move(effect.element,
      { x: -distance, y: 0, duration: split, afterFinishInternal: function(effect) {
        effect.element.undoPositioned().setStyle(oldStyle);
  }}) }}) }}) }}) }}) }});
};

Effect.SlideDown = function(element) {
  element = $(element).cleanWhitespace();
  // SlideDown need to have the content of the element wrapped in a container element with fixed height!
  var oldInnerBottom = element.down().getStyle('bottom');
  var elementDimensions = element.getDimensions();
  return new Effect.Scale(element, 100, Object.extend({ 
    scaleContent: false, 
    scaleX: false, 
    scaleFrom: window.opera ? 0 : 1,
    scaleMode: {originalHeight: elementDimensions.height, originalWidth: elementDimensions.width},
    restoreAfterFinish: true,
    afterSetup: function(effect) {
      effect.element.makePositioned();
      effect.element.down().makePositioned();
      if (window.opera) effect.element.setStyle({top: ''});
      effect.element.makeClipping().setStyle({height: '0px'}).show(); 
    },
    afterUpdateInternal: function(effect) {
      effect.element.down().setStyle({bottom:
        (effect.dims[0] - effect.element.clientHeight) + 'px' }); 
    },
    afterFinishInternal: function(effect) {
      effect.element.undoClipping().undoPositioned();
      effect.element.down().undoPositioned().setStyle({bottom: oldInnerBottom}); }
    }, arguments[1] || { })
  );
};

Effect.SlideUp = function(element) {
  element = $(element).cleanWhitespace();
  var oldInnerBottom = element.down().getStyle('bottom');
  var elementDimensions = element.getDimensions();
  return new Effect.Scale(element, window.opera ? 0 : 1,
   Object.extend({ scaleContent: false, 
    scaleX: false, 
    scaleMode: 'box',
    scaleFrom: 100,
    scaleMode: {originalHeight: elementDimensions.height, originalWidth: elementDimensions.width},
    restoreAfterFinish: true,
    afterSetup: function(effect) {
      effect.element.makePositioned();
      effect.element.down().makePositioned();
      if (window.opera) effect.element.setStyle({top: ''});
      effect.element.makeClipping().show();
    },  
    afterUpdateInternal: function(effect) {
      effect.element.down().setStyle({bottom:
        (effect.dims[0] - effect.element.clientHeight) + 'px' });
    },
    afterFinishInternal: function(effect) {
      effect.element.hide().undoClipping().undoPositioned();
      effect.element.down().undoPositioned().setStyle({bottom: oldInnerBottom});
    }
   }, arguments[1] || { })
  );
};

// Bug in opera makes the TD containing this element expand for a instance after finish 
Effect.Squish = function(element) {
  return new Effect.Scale(element, window.opera ? 1 : 0, { 
    restoreAfterFinish: true,
    beforeSetup: function(effect) {
      effect.element.makeClipping(); 
    },  
    afterFinishInternal: function(effect) {
      effect.element.hide().undoClipping(); 
    }
  });
};

Effect.Grow = function(element) {
  element = $(element);
  var options = Object.extend({
    direction: 'center',
    moveTransition: Effect.Transitions.sinoidal,
    scaleTransition: Effect.Transitions.sinoidal,
    opacityTransition: Effect.Transitions.full
  }, arguments[1] || { });
  var oldStyle = {
    top: element.style.top,
    left: element.style.left,
    height: element.style.height,
    width: element.style.width,
    opacity: element.getInlineOpacity() };

  var dims = element.getDimensions();    
  var initialMoveX, initialMoveY;
  var moveX, moveY;
  
  switch (options.direction) {
    case 'top-left':
      initialMoveX = initialMoveY = moveX = moveY = 0; 
      break;
    case 'top-right':
      initialMoveX = dims.width;
      initialMoveY = moveY = 0;
      moveX = -dims.width;
      break;
    case 'bottom-left':
      initialMoveX = moveX = 0;
      initialMoveY = dims.height;
      moveY = -dims.height;
      break;
    case 'bottom-right':
      initialMoveX = dims.width;
      initialMoveY = dims.height;
      moveX = -dims.width;
      moveY = -dims.height;
      break;
    case 'center':
      initialMoveX = dims.width / 2;
      initialMoveY = dims.height / 2;
      moveX = -dims.width / 2;
      moveY = -dims.height / 2;
      break;
  }
  
  return new Effect.Move(element, {
    x: initialMoveX,
    y: initialMoveY,
    duration: 0.01, 
    beforeSetup: function(effect) {
      effect.element.hide().makeClipping().makePositioned();
    },
    afterFinishInternal: function(effect) {
      new Effect.Parallel(
        [ new Effect.Opacity(effect.element, { sync: true, to: 1.0, from: 0.0, transition: options.opacityTransition }),
          new Effect.Move(effect.element, { x: moveX, y: moveY, sync: true, transition: options.moveTransition }),
          new Effect.Scale(effect.element, 100, {
            scaleMode: { originalHeight: dims.height, originalWidth: dims.width }, 
            sync: true, scaleFrom: window.opera ? 1 : 0, transition: options.scaleTransition, restoreAfterFinish: true})
        ], Object.extend({
             beforeSetup: function(effect) {
               effect.effects[0].element.setStyle({height: '0px'}).show(); 
             },
             afterFinishInternal: function(effect) {
               effect.effects[0].element.undoClipping().undoPositioned().setStyle(oldStyle); 
             }
           }, options)
      )
    }
  });
};

Effect.Shrink = function(element) {
  element = $(element);
  var options = Object.extend({
    direction: 'center',
    moveTransition: Effect.Transitions.sinoidal,
    scaleTransition: Effect.Transitions.sinoidal,
    opacityTransition: Effect.Transitions.none
  }, arguments[1] || { });
  var oldStyle = {
    top: element.style.top,
    left: element.style.left,
    height: element.style.height,
    width: element.style.width,
    opacity: element.getInlineOpacity() };

  var dims = element.getDimensions();
  var moveX, moveY;
  
  switch (options.direction) {
    case 'top-left':
      moveX = moveY = 0;
      break;
    case 'top-right':
      moveX = dims.width;
      moveY = 0;
      break;
    case 'bottom-left':
      moveX = 0;
      moveY = dims.height;
      break;
    case 'bottom-right':
      moveX = dims.width;
      moveY = dims.height;
      break;
    case 'center':  
      moveX = dims.width / 2;
      moveY = dims.height / 2;
      break;
  }
  
  return new Effect.Parallel(
    [ new Effect.Opacity(element, { sync: true, to: 0.0, from: 1.0, transition: options.opacityTransition }),
      new Effect.Scale(element, window.opera ? 1 : 0, { sync: true, transition: options.scaleTransition, restoreAfterFinish: true}),
      new Effect.Move(element, { x: moveX, y: moveY, sync: true, transition: options.moveTransition })
    ], Object.extend({            
         beforeStartInternal: function(effect) {
           effect.effects[0].element.makePositioned().makeClipping(); 
         },
         afterFinishInternal: function(effect) {
           effect.effects[0].element.hide().undoClipping().undoPositioned().setStyle(oldStyle); }
       }, options)
  );
};

Effect.Pulsate = function(element) {
  element = $(element);
  var options    = arguments[1] || { };
  var oldOpacity = element.getInlineOpacity();
  var transition = options.transition || Effect.Transitions.sinoidal;
  var reverser   = function(pos){ return transition(1-Effect.Transitions.pulse(pos, options.pulses)) };
  reverser.bind(transition);
  return new Effect.Opacity(element, 
    Object.extend(Object.extend({  duration: 2.0, from: 0,
      afterFinishInternal: function(effect) { effect.element.setStyle({opacity: oldOpacity}); }
    }, options), {transition: reverser}));
};

Effect.Fold = function(element) {
  element = $(element);
  var oldStyle = {
    top: element.style.top,
    left: element.style.left,
    width: element.style.width,
    height: element.style.height };
  element.makeClipping();
  return new Effect.Scale(element, 5, Object.extend({   
    scaleContent: false,
    scaleX: false,
    afterFinishInternal: function(effect) {
    new Effect.Scale(element, 1, { 
      scaleContent: false, 
      scaleY: false,
      afterFinishInternal: function(effect) {
        effect.element.hide().undoClipping().setStyle(oldStyle);
      } });
  }}, arguments[1] || { }));
};

Effect.Morph = Class.create(Effect.Base, {
  initialize: function(element) {
    this.element = $(element);
    if (!this.element) throw(Effect._elementDoesNotExistError);
    var options = Object.extend({
      style: { }
    }, arguments[1] || { });
    
    if (!Object.isString(options.style)) this.style = $H(options.style);
    else {
      if (options.style.include(':'))
        this.style = options.style.parseStyle();
      else {
        this.element.addClassName(options.style);
        this.style = $H(this.element.getStyles());
        this.element.removeClassName(options.style);
        var css = this.element.getStyles();
        this.style = this.style.reject(function(style) {
          return style.value == css[style.key];
        });
        options.afterFinishInternal = function(effect) {
          effect.element.addClassName(effect.options.style);
          effect.transforms.each(function(transform) {
            effect.element.style[transform.style] = '';
          });
        }
      }
    }
    this.start(options);
  },
  
  setup: function(){
    function parseColor(color){
      if (!color || ['rgba(0, 0, 0, 0)','transparent'].include(color)) color = '#ffffff';
      color = color.parseColor();
      return $R(0,2).map(function(i){
        return parseInt( color.slice(i*2+1,i*2+3), 16 ) 
      });
    }
    this.transforms = this.style.map(function(pair){
      var property = pair[0], value = pair[1], unit = null;

      if (value.parseColor('#zzzzzz') != '#zzzzzz') {
        value = value.parseColor();
        unit  = 'color';
      } else if (property == 'opacity') {
        value = parseFloat(value);
        if (Prototype.Browser.IE && (!this.element.currentStyle.hasLayout))
          this.element.setStyle({zoom: 1});
      } else if (Element.CSS_LENGTH.test(value)) {
          var components = value.match(/^([\+\-]?[0-9\.]+)(.*)$/);
          value = parseFloat(components[1]);
          unit = (components.length == 3) ? components[2] : null;
      }

      var originalValue = this.element.getStyle(property);
      return { 
        style: property.camelize(), 
        originalValue: unit=='color' ? parseColor(originalValue) : parseFloat(originalValue || 0), 
        targetValue: unit=='color' ? parseColor(value) : value,
        unit: unit
      };
    }.bind(this)).reject(function(transform){
      return (
        (transform.originalValue == transform.targetValue) ||
        (
          transform.unit != 'color' &&
          (isNaN(transform.originalValue) || isNaN(transform.targetValue))
        )
      )
    });
  },
  update: function(position) {
    var style = { }, transform, i = this.transforms.length;
    while(i--)
      style[(transform = this.transforms[i]).style] = 
        transform.unit=='color' ? '#'+
          (Math.round(transform.originalValue[0]+
            (transform.targetValue[0]-transform.originalValue[0])*position)).toColorPart() +
          (Math.round(transform.originalValue[1]+
            (transform.targetValue[1]-transform.originalValue[1])*position)).toColorPart() +
          (Math.round(transform.originalValue[2]+
            (transform.targetValue[2]-transform.originalValue[2])*position)).toColorPart() :
        (transform.originalValue +
          (transform.targetValue - transform.originalValue) * position).toFixed(3) + 
            (transform.unit === null ? '' : transform.unit);
    this.element.setStyle(style, true);
  }
});

Effect.Transform = Class.create({
  initialize: function(tracks){
    this.tracks  = [];
    this.options = arguments[1] || { };
    this.addTracks(tracks);
  },
  addTracks: function(tracks){
    tracks.each(function(track){
      track = $H(track);
      var data = track.values().first();
      this.tracks.push($H({
        ids:     track.keys().first(),
        effect:  Effect.Morph,
        options: { style: data }
      }));
    }.bind(this));
    return this;
  },
  play: function(){
    return new Effect.Parallel(
      this.tracks.map(function(track){
        var ids = track.get('ids'), effect = track.get('effect'), options = track.get('options');
        var elements = [$(ids) || $$(ids)].flatten();
        return elements.map(function(e){ return new effect(e, Object.extend({ sync:true }, options)) });
      }).flatten(),
      this.options
    );
  }
});

Element.CSS_PROPERTIES = $w(
  'backgroundColor backgroundPosition borderBottomColor borderBottomStyle ' + 
  'borderBottomWidth borderLeftColor borderLeftStyle borderLeftWidth ' +
  'borderRightColor borderRightStyle borderRightWidth borderSpacing ' +
  'borderTopColor borderTopStyle borderTopWidth bottom clip color ' +
  'fontSize fontWeight height left letterSpacing lineHeight ' +
  'marginBottom marginLeft marginRight marginTop markerOffset maxHeight '+
  'maxWidth minHeight minWidth opacity outlineColor outlineOffset ' +
  'outlineWidth paddingBottom paddingLeft paddingRight paddingTop ' +
  'right textIndent top width wordSpacing zIndex');
  
Element.CSS_LENGTH = /^(([\+\-]?[0-9\.]+)(em|ex|px|in|cm|mm|pt|pc|\%))|0$/;

String.__parseStyleElement = document.createElement('div');
String.prototype.parseStyle = function(){
  var style, styleRules = $H();
  if (Prototype.Browser.WebKit)
    style = new Element('div',{style:this}).style;
  else {
    String.__parseStyleElement.innerHTML = '<div style="' + this + '"></div>';
    style = String.__parseStyleElement.childNodes[0].style;
  }
  
  Element.CSS_PROPERTIES.each(function(property){
    if (style[property]) styleRules.set(property, style[property]); 
  });
  
  if (Prototype.Browser.IE && this.include('opacity'))
    styleRules.set('opacity', this.match(/opacity:\s*((?:0|1)?(?:\.\d*)?)/)[1]);

  return styleRules;
};

if (document.defaultView && document.defaultView.getComputedStyle) {
  Element.getStyles = function(element) {
    var css = document.defaultView.getComputedStyle($(element), null);
    return Element.CSS_PROPERTIES.inject({ }, function(styles, property) {
      styles[property] = css[property];
      return styles;
    });
  };
} else {
  Element.getStyles = function(element) {
    element = $(element);
    var css = element.currentStyle, styles;
    styles = Element.CSS_PROPERTIES.inject({ }, function(hash, property) {
      hash.set(property, css[property]);
      return hash;
    });
    if (!styles.opacity) styles.set('opacity', element.getOpacity());
    return styles;
  };
};

Effect.Methods = {
  morph: function(element, style) {
    element = $(element);
    new Effect.Morph(element, Object.extend({ style: style }, arguments[2] || { }));
    return element;
  },
  visualEffect: function(element, effect, options) {
    element = $(element)
    var s = effect.dasherize().camelize(), klass = s.charAt(0).toUpperCase() + s.substring(1);
    new Effect[klass](element, options);
    return element;
  },
  highlight: function(element, options) {
    element = $(element);
    new Effect.Highlight(element, options);
    return element;
  }
};

$w('fade appear grow shrink fold blindUp blindDown slideUp slideDown '+
  'pulsate shake puff squish switchOff dropOut').each(
  function(effect) { 
    Effect.Methods[effect] = function(element, options){
      element = $(element);
      Effect[effect.charAt(0).toUpperCase() + effect.substring(1)](element, options);
      return element;
    }
  }
);

$w('getInlineOpacity forceRerendering setContentZoom collectTextNodes collectTextNodesIgnoreClass getStyles').each( 
  function(f) { Effect.Methods[f] = Element[f]; }
);

Element.addMethods(Effect.Methods);


// Copyright (c) 2005-2008 Thomas Fuchs (http://script.aculo.us, http://mir.aculo.us)
//           (c) 2005-2007 Sammi Williams (http://www.oriontransfer.co.nz, sammi@oriontransfer.co.nz)
// 
// script.aculo.us is freely distributable under the terms of an MIT-style license.
// For details, see the script.aculo.us web site: http://script.aculo.us/

if(Object.isUndefined(Effect))
  throw("dragdrop.js requires including script.aculo.us' effects.js library");

var Droppables = {
  drops: [],

  remove: function(element) {
    this.drops = this.drops.reject(function(d) { return d.element==$(element) });
  },

  add: function(element) {
    element = $(element);
    var options = Object.extend({
      greedy:     true,
      hoverclass: null,
      tree:       false
    }, arguments[1] || { });

    // cache containers
    if(options.containment) {
      options._containers = [];
      var containment = options.containment;
      if(Object.isArray(containment)) {
        containment.each( function(c) { options._containers.push($(c)) });
      } else {
        options._containers.push($(containment));
      }
    }
    
    if(options.accept) options.accept = [options.accept].flatten();

    Element.makePositioned(element); // fix IE
    options.element = element;

    this.drops.push(options);
  },
  
  findDeepestChild: function(drops) {
    deepest = drops[0];
      
    for (i = 1; i < drops.length; ++i)
      if (Element.isParent(drops[i].element, deepest.element))
        deepest = drops[i];
    
    return deepest;
  },

  isContained: function(element, drop) {
    var containmentNode;
    if(drop.tree) {
      containmentNode = element.treeNode; 
    } else {
      containmentNode = element.parentNode;
    }
    return drop._containers.detect(function(c) { return containmentNode == c });
  },
  
  isAffected: function(point, element, drop) {
    return (
      (drop.element!=element) &&
      ((!drop._containers) ||
        this.isContained(element, drop)) &&
      ((!drop.accept) ||
        (Element.classNames(element).detect( 
          function(v) { return drop.accept.include(v) } ) )) &&
      Position.within(drop.element, point[0], point[1]) );
  },

  deactivate: function(drop) {
    if(drop.hoverclass)
      Element.removeClassName(drop.element, drop.hoverclass);
    this.last_active = null;
  },

  activate: function(drop) {
    if(drop.hoverclass)
      Element.addClassName(drop.element, drop.hoverclass);
    this.last_active = drop;
  },

  show: function(point, element) {
    if(!this.drops.length) return;
    var drop, affected = [];
    
    this.drops.each( function(drop) {
      if(Droppables.isAffected(point, element, drop))
        affected.push(drop);
    });
        
    if(affected.length>0)
      drop = Droppables.findDeepestChild(affected);

    if(this.last_active && this.last_active != drop) this.deactivate(this.last_active);
    if (drop) {
      Position.within(drop.element, point[0], point[1]);
      if(drop.onHover)
        drop.onHover(element, drop.element, Position.overlap(drop.overlap, drop.element));
      
      if (drop != this.last_active) Droppables.activate(drop);
    }
  },

  fire: function(event, element) {
    if(!this.last_active) return;
    Position.prepare();

    if (this.isAffected([Event.pointerX(event), Event.pointerY(event)], element, this.last_active))
      if (this.last_active.onDrop) {
        this.last_active.onDrop(element, this.last_active.element, event); 
        return true; 
      }
  },

  reset: function() {
    if(this.last_active)
      this.deactivate(this.last_active);
  }
}

var Draggables = {
  drags: [],
  observers: [],
  
  register: function(draggable) {
    if(this.drags.length == 0) {
      this.eventMouseUp   = this.endDrag.bindAsEventListener(this);
      this.eventMouseMove = this.updateDrag.bindAsEventListener(this);
      this.eventKeypress  = this.keyPress.bindAsEventListener(this);
      
      Event.observe(document, "mouseup", this.eventMouseUp);
      Event.observe(document, "mousemove", this.eventMouseMove);
      Event.observe(document, "keypress", this.eventKeypress);
    }
    this.drags.push(draggable);
  },
  
  unregister: function(draggable) {
    this.drags = this.drags.reject(function(d) { return d==draggable });
    if(this.drags.length == 0) {
      Event.stopObserving(document, "mouseup", this.eventMouseUp);
      Event.stopObserving(document, "mousemove", this.eventMouseMove);
      Event.stopObserving(document, "keypress", this.eventKeypress);
    }
  },
  
  activate: function(draggable) {
    if(draggable.options.delay) { 
      this._timeout = setTimeout(function() { 
        Draggables._timeout = null; 
        window.focus(); 
        Draggables.activeDraggable = draggable; 
      }.bind(this), draggable.options.delay); 
    } else {
      window.focus(); // allows keypress events if window isn't currently focused, fails for Safari
      this.activeDraggable = draggable;
    }
  },
  
  deactivate: function() {
    this.activeDraggable = null;
  },
  
  updateDrag: function(event) {
    if(!this.activeDraggable) return;
    var pointer = [Event.pointerX(event), Event.pointerY(event)];
    // Mozilla-based browsers fire successive mousemove events with
    // the same coordinates, prevent needless redrawing (moz bug?)
    if(this._lastPointer && (this._lastPointer.inspect() == pointer.inspect())) return;
    this._lastPointer = pointer;
    
    this.activeDraggable.updateDrag(event, pointer);
  },
  
  endDrag: function(event) {
    if(this._timeout) { 
      clearTimeout(this._timeout); 
      this._timeout = null; 
    }
    if(!this.activeDraggable) return;
    this._lastPointer = null;
    this.activeDraggable.endDrag(event);
    this.activeDraggable = null;
  },
  
  keyPress: function(event) {
    if(this.activeDraggable)
      this.activeDraggable.keyPress(event);
  },
  
  addObserver: function(observer) {
    this.observers.push(observer);
    this._cacheObserverCallbacks();
  },
  
  removeObserver: function(element) {  // element instead of observer fixes mem leaks
    this.observers = this.observers.reject( function(o) { return o.element==element });
    this._cacheObserverCallbacks();
  },
  
  notify: function(eventName, draggable, event) {  // 'onStart', 'onEnd', 'onDrag'
    if(this[eventName+'Count'] > 0)
      this.observers.each( function(o) {
        if(o[eventName]) o[eventName](eventName, draggable, event);
      });
    if(draggable.options[eventName]) draggable.options[eventName](draggable, event);
  },
  
  _cacheObserverCallbacks: function() {
    ['onStart','onEnd','onDrag'].each( function(eventName) {
      Draggables[eventName+'Count'] = Draggables.observers.select(
        function(o) { return o[eventName]; }
      ).length;
    });
  }
}

/*--------------------------------------------------------------------------*/

var Draggable = Class.create({
  initialize: function(element) {
    var defaults = {
      handle: false,
      reverteffect: function(element, top_offset, left_offset) {
        var dur = Math.sqrt(Math.abs(top_offset^2)+Math.abs(left_offset^2))*0.02;
        new Effect.Move(element, { x: -left_offset, y: -top_offset, duration: dur,
          queue: {scope:'_draggable', position:'end'}
        });
      },
      endeffect: function(element) {
        var toOpacity = Object.isNumber(element._opacity) ? element._opacity : 1.0;
        new Effect.Opacity(element, {duration:0.2, from:0.7, to:toOpacity, 
          queue: {scope:'_draggable', position:'end'},
          afterFinish: function(){ 
            Draggable._dragging[element] = false 
          }
        }); 
      },
      zindex: 1000,
      revert: false,
      quiet: false,
      scroll: false,
      scrollSensitivity: 20,
      scrollSpeed: 15,
      snap: false,  // false, or xy or [x,y] or function(x,y){ return [x,y] }
      delay: 0
    };
    
    if(!arguments[1] || Object.isUndefined(arguments[1].endeffect))
      Object.extend(defaults, {
        starteffect: function(element) {
          element._opacity = Element.getOpacity(element);
          Draggable._dragging[element] = true;
          new Effect.Opacity(element, {duration:0.2, from:element._opacity, to:0.7}); 
        }
      });
    
    var options = Object.extend(defaults, arguments[1] || { });

    this.element = $(element);
    
    if(options.handle && Object.isString(options.handle))
      this.handle = this.element.down('.'+options.handle, 0);
    
    if(!this.handle) this.handle = $(options.handle);
    if(!this.handle) this.handle = this.element;
    
    if(options.scroll && !options.scroll.scrollTo && !options.scroll.outerHTML) {
      options.scroll = $(options.scroll);
      this._isScrollChild = Element.childOf(this.element, options.scroll);
    }

    Element.makePositioned(this.element); // fix IE    

    this.options  = options;
    this.dragging = false;   

    this.eventMouseDown = this.initDrag.bindAsEventListener(this);
    Event.observe(this.handle, "mousedown", this.eventMouseDown);
    
    Draggables.register(this);
  },
  
  destroy: function() {
    Event.stopObserving(this.handle, "mousedown", this.eventMouseDown);
    Draggables.unregister(this);
  },
  
  currentDelta: function() {
    return([
      parseInt(Element.getStyle(this.element,'left') || '0'),
      parseInt(Element.getStyle(this.element,'top') || '0')]);
  },
  
  initDrag: function(event) {
    if(!Object.isUndefined(Draggable._dragging[this.element]) &&
      Draggable._dragging[this.element]) return;
    if(Event.isLeftClick(event)) {    
      // abort on form elements, fixes a Firefox issue
      var src = Event.element(event);
      if((tag_name = src.tagName.toUpperCase()) && (
        tag_name=='INPUT' ||
        tag_name=='SELECT' ||
        tag_name=='OPTION' ||
        tag_name=='BUTTON' ||
        tag_name=='TEXTAREA')) return;
        
      var pointer = [Event.pointerX(event), Event.pointerY(event)];
      var pos     = Position.cumulativeOffset(this.element);
      this.offset = [0,1].map( function(i) { return (pointer[i] - pos[i]) });
      
      Draggables.activate(this);
      Event.stop(event);
    }
  },
  
  startDrag: function(event) {
    this.dragging = true;
    if(!this.delta)
      this.delta = this.currentDelta();
    
    if(this.options.zindex) {
      this.originalZ = parseInt(Element.getStyle(this.element,'z-index') || 0);
      this.element.style.zIndex = this.options.zindex;
    }
    
    if(this.options.ghosting) {
      this._clone = this.element.cloneNode(true);
      this.element._originallyAbsolute = (this.element.getStyle('position') == 'absolute');
      if (!this.element._originallyAbsolute)
        Position.absolutize(this.element);
      this.element.parentNode.insertBefore(this._clone, this.element);
    }
    
    if(this.options.scroll) {
      if (this.options.scroll == window) {
        var where = this._getWindowScroll(this.options.scroll);
        this.originalScrollLeft = where.left;
        this.originalScrollTop = where.top;
      } else {
        this.originalScrollLeft = this.options.scroll.scrollLeft;
        this.originalScrollTop = this.options.scroll.scrollTop;
      }
    }
    
    Draggables.notify('onStart', this, event);
        
    if(this.options.starteffect) this.options.starteffect(this.element);
  },
  
  updateDrag: function(event, pointer) {
    if(!this.dragging) this.startDrag(event);
    
    if(!this.options.quiet){
      Position.prepare();
      Droppables.show(pointer, this.element);
    }
    
    Draggables.notify('onDrag', this, event);
    
    this.draw(pointer);
    if(this.options.change) this.options.change(this);
    
    if(this.options.scroll) {
      this.stopScrolling();
      
      var p;
      if (this.options.scroll == window) {
        with(this._getWindowScroll(this.options.scroll)) { p = [ left, top, left+width, top+height ]; }
      } else {
        p = Position.page(this.options.scroll);
        p[0] += this.options.scroll.scrollLeft + Position.deltaX;
        p[1] += this.options.scroll.scrollTop + Position.deltaY;
        p.push(p[0]+this.options.scroll.offsetWidth);
        p.push(p[1]+this.options.scroll.offsetHeight);
      }
      var speed = [0,0];
      if(pointer[0] < (p[0]+this.options.scrollSensitivity)) speed[0] = pointer[0]-(p[0]+this.options.scrollSensitivity);
      if(pointer[1] < (p[1]+this.options.scrollSensitivity)) speed[1] = pointer[1]-(p[1]+this.options.scrollSensitivity);
      if(pointer[0] > (p[2]-this.options.scrollSensitivity)) speed[0] = pointer[0]-(p[2]-this.options.scrollSensitivity);
      if(pointer[1] > (p[3]-this.options.scrollSensitivity)) speed[1] = pointer[1]-(p[3]-this.options.scrollSensitivity);
      this.startScrolling(speed);
    }
    
    // fix AppleWebKit rendering
    if(Prototype.Browser.WebKit) window.scrollBy(0,0);
    
    Event.stop(event);
  },
  
  finishDrag: function(event, success) {
    this.dragging = false;
    
    if(this.options.quiet){
      Position.prepare();
      var pointer = [Event.pointerX(event), Event.pointerY(event)];
      Droppables.show(pointer, this.element);
    }

    if(this.options.ghosting) {
      if (!this.element._originallyAbsolute)
        Position.relativize(this.element);
      delete this.element._originallyAbsolute;
      Element.remove(this._clone);
      this._clone = null;
    }

    var dropped = false; 
    if(success) { 
      dropped = Droppables.fire(event, this.element); 
      if (!dropped) dropped = false; 
    }
    if(dropped && this.options.onDropped) this.options.onDropped(this.element);
    Draggables.notify('onEnd', this, event);

    var revert = this.options.revert;
    if(revert && Object.isFunction(revert)) revert = revert(this.element);
    
    var d = this.currentDelta();
    if(revert && this.options.reverteffect) {
      if (dropped == 0 || revert != 'failure')
        this.options.reverteffect(this.element,
          d[1]-this.delta[1], d[0]-this.delta[0]);
    } else {
      this.delta = d;
    }

    if(this.options.zindex)
      this.element.style.zIndex = this.originalZ;

    if(this.options.endeffect) 
      this.options.endeffect(this.element);
      
    Draggables.deactivate(this);
    Droppables.reset();
  },
  
  keyPress: function(event) {
    if(event.keyCode!=Event.KEY_ESC) return;
    this.finishDrag(event, false);
    Event.stop(event);
  },
  
  endDrag: function(event) {
    if(!this.dragging) return;
    this.stopScrolling();
    this.finishDrag(event, true);
    Event.stop(event);
  },
  
  draw: function(point) {
    var pos = Position.cumulativeOffset(this.element);
    if(this.options.ghosting) {
      var r   = Position.realOffset(this.element);
      pos[0] += r[0] - Position.deltaX; pos[1] += r[1] - Position.deltaY;
    }
    
    var d = this.currentDelta();
    pos[0] -= d[0]; pos[1] -= d[1];
    
    if(this.options.scroll && (this.options.scroll != window && this._isScrollChild)) {
      pos[0] -= this.options.scroll.scrollLeft-this.originalScrollLeft;
      pos[1] -= this.options.scroll.scrollTop-this.originalScrollTop;
    }
    
    var p = [0,1].map(function(i){ 
      return (point[i]-pos[i]-this.offset[i]) 
    }.bind(this));
    
    if(this.options.snap) {
      if(Object.isFunction(this.options.snap)) {
        p = this.options.snap(p[0],p[1],this);
      } else {
      if(Object.isArray(this.options.snap)) {
        p = p.map( function(v, i) {
          return (v/this.options.snap[i]).round()*this.options.snap[i] }.bind(this))
      } else {
        p = p.map( function(v) {
          return (v/this.options.snap).round()*this.options.snap }.bind(this))
      }
    }}
    
    var style = this.element.style;
    if((!this.options.constraint) || (this.options.constraint=='horizontal'))
      style.left = p[0] + "px";
    if((!this.options.constraint) || (this.options.constraint=='vertical'))
      style.top  = p[1] + "px";
    
    if(style.visibility=="hidden") style.visibility = ""; // fix gecko rendering
  },
  
  stopScrolling: function() {
    if(this.scrollInterval) {
      clearInterval(this.scrollInterval);
      this.scrollInterval = null;
      Draggables._lastScrollPointer = null;
    }
  },
  
  startScrolling: function(speed) {
    if(!(speed[0] || speed[1])) return;
    this.scrollSpeed = [speed[0]*this.options.scrollSpeed,speed[1]*this.options.scrollSpeed];
    this.lastScrolled = new Date();
    this.scrollInterval = setInterval(this.scroll.bind(this), 10);
  },
  
  scroll: function() {
    var current = new Date();
    var delta = current - this.lastScrolled;
    this.lastScrolled = current;
    if(this.options.scroll == window) {
      with (this._getWindowScroll(this.options.scroll)) {
        if (this.scrollSpeed[0] || this.scrollSpeed[1]) {
          var d = delta / 1000;
          this.options.scroll.scrollTo( left + d*this.scrollSpeed[0], top + d*this.scrollSpeed[1] );
        }
      }
    } else {
      this.options.scroll.scrollLeft += this.scrollSpeed[0] * delta / 1000;
      this.options.scroll.scrollTop  += this.scrollSpeed[1] * delta / 1000;
    }
    
    Position.prepare();
    Droppables.show(Draggables._lastPointer, this.element);
    Draggables.notify('onDrag', this);
    if (this._isScrollChild) {
      Draggables._lastScrollPointer = Draggables._lastScrollPointer || $A(Draggables._lastPointer);
      Draggables._lastScrollPointer[0] += this.scrollSpeed[0] * delta / 1000;
      Draggables._lastScrollPointer[1] += this.scrollSpeed[1] * delta / 1000;
      if (Draggables._lastScrollPointer[0] < 0)
        Draggables._lastScrollPointer[0] = 0;
      if (Draggables._lastScrollPointer[1] < 0)
        Draggables._lastScrollPointer[1] = 0;
      this.draw(Draggables._lastScrollPointer);
    }
    
    if(this.options.change) this.options.change(this);
  },
  
  _getWindowScroll: function(w) {
    var T, L, W, H;
    with (w.document) {
      if (w.document.documentElement && documentElement.scrollTop) {
        T = documentElement.scrollTop;
        L = documentElement.scrollLeft;
      } else if (w.document.body) {
        T = body.scrollTop;
        L = body.scrollLeft;
      }
      if (w.innerWidth) {
        W = w.innerWidth;
        H = w.innerHeight;
      } else if (w.document.documentElement && documentElement.clientWidth) {
        W = documentElement.clientWidth;
        H = documentElement.clientHeight;
      } else {
        W = body.offsetWidth;
        H = body.offsetHeight
      }
    }
    return { top: T, left: L, width: W, height: H };
  }
});

Draggable._dragging = { };

/*--------------------------------------------------------------------------*/

var SortableObserver = Class.create({
  initialize: function(element, observer) {
    this.element   = $(element);
    this.observer  = observer;
    this.lastValue = Sortable.serialize(this.element);
  },
  
  onStart: function() {
    this.lastValue = Sortable.serialize(this.element);
  },
  
  onEnd: function() {
    Sortable.unmark();
    if(this.lastValue != Sortable.serialize(this.element))
      this.observer(this.element)
  }
});

var Sortable = {
  SERIALIZE_RULE: /^[^_\-](?:[A-Za-z0-9\-\_]*)[_](.*)$/,
  
  sortables: { },
  
  _findRootElement: function(element) {
    while (element.tagName.toUpperCase() != "BODY") {  
      if(element.id && Sortable.sortables[element.id]) return element;
      element = element.parentNode;
    }
  },

  options: function(element) {
    element = Sortable._findRootElement($(element));
    if(!element) return;
    return Sortable.sortables[element.id];
  },
  
  destroy: function(element){
    var s = Sortable.options(element);
    
    if(s) {
      Draggables.removeObserver(s.element);
      s.droppables.each(function(d){ Droppables.remove(d) });
      s.draggables.invoke('destroy');
      
      delete Sortable.sortables[s.element.id];
    }
  },

  create: function(element) {
    element = $(element);
    var options = Object.extend({ 
      element:     element,
      tag:         'li',       // assumes li children, override with tag: 'tagname'
      dropOnEmpty: false,
      tree:        false,
      treeTag:     'ul',
      overlap:     'vertical', // one of 'vertical', 'horizontal'
      constraint:  'vertical', // one of 'vertical', 'horizontal', false
      containment: element,    // also takes array of elements (or id's); or false
      handle:      false,      // or a CSS class
      only:        false,
      delay:       0,
      hoverclass:  null,
      ghosting:    false,
      quiet:       false, 
      scroll:      false,
      scrollSensitivity: 20,
      scrollSpeed: 15,
      format:      this.SERIALIZE_RULE,
      
      // these take arrays of elements or ids and can be 
      // used for better initialization performance
      elements:    false,
      handles:     false,
      
      onChange:    Prototype.emptyFunction,
      onUpdate:    Prototype.emptyFunction
    }, arguments[1] || { });

    // clear any old sortable with same element
    this.destroy(element);

    // build options for the draggables
    var options_for_draggable = {
      revert:      true,
      quiet:       options.quiet,
      scroll:      options.scroll,
      scrollSpeed: options.scrollSpeed,
      scrollSensitivity: options.scrollSensitivity,
      delay:       options.delay,
      ghosting:    options.ghosting,
      constraint:  options.constraint,
      handle:      options.handle };

    if(options.starteffect)
      options_for_draggable.starteffect = options.starteffect;

    if(options.reverteffect)
      options_for_draggable.reverteffect = options.reverteffect;
    else
      if(options.ghosting) options_for_draggable.reverteffect = function(element) {
        element.style.top  = 0;
        element.style.left = 0;
      };

    if(options.endeffect)
      options_for_draggable.endeffect = options.endeffect;

    if(options.zindex)
      options_for_draggable.zindex = options.zindex;

    // build options for the droppables  
    var options_for_droppable = {
      overlap:     options.overlap,
      containment: options.containment,
      tree:        options.tree,
      hoverclass:  options.hoverclass,
      onHover:     Sortable.onHover
    }
    
    var options_for_tree = {
      onHover:      Sortable.onEmptyHover,
      overlap:      options.overlap,
      containment:  options.containment,
      hoverclass:   options.hoverclass
    }

    // fix for gecko engine
    Element.cleanWhitespace(element); 

    options.draggables = [];
    options.droppables = [];

    // drop on empty handling
    if(options.dropOnEmpty || options.tree) {
      Droppables.add(element, options_for_tree);
      options.droppables.push(element);
    }

    (options.elements || this.findElements(element, options) || []).each( function(e,i) {
      var handle = options.handles ? $(options.handles[i]) :
        (options.handle ? $(e).select('.' + options.handle)[0] : e); 
      options.draggables.push(
        new Draggable(e, Object.extend(options_for_draggable, { handle: handle })));
      Droppables.add(e, options_for_droppable);
      if(options.tree) e.treeNode = element;
      options.droppables.push(e);      
    });
    
    if(options.tree) {
      (Sortable.findTreeElements(element, options) || []).each( function(e) {
        Droppables.add(e, options_for_tree);
        e.treeNode = element;
        options.droppables.push(e);
      });
    }

    // keep reference
    this.sortables[element.id] = options;

    // for onupdate
    Draggables.addObserver(new SortableObserver(element, options.onUpdate));

  },

  // return all suitable-for-sortable elements in a guaranteed order
  findElements: function(element, options) {
    return Element.findChildren(
      element, options.only, options.tree ? true : false, options.tag);
  },
  
  findTreeElements: function(element, options) {
    return Element.findChildren(
      element, options.only, options.tree ? true : false, options.treeTag);
  },

  onHover: function(element, dropon, overlap) {
    if(Element.isParent(dropon, element)) return;

    if(overlap > .33 && overlap < .66 && Sortable.options(dropon).tree) {
      return;
    } else if(overlap>0.5) {
      Sortable.mark(dropon, 'before');
      if(dropon.previousSibling != element) {
        var oldParentNode = element.parentNode;
        element.style.visibility = "hidden"; // fix gecko rendering
        dropon.parentNode.insertBefore(element, dropon);
        if(dropon.parentNode!=oldParentNode) 
          Sortable.options(oldParentNode).onChange(element);
        Sortable.options(dropon.parentNode).onChange(element);
      }
    } else {
      Sortable.mark(dropon, 'after');
      var nextElement = dropon.nextSibling || null;
      if(nextElement != element) {
        var oldParentNode = element.parentNode;
        element.style.visibility = "hidden"; // fix gecko rendering
        dropon.parentNode.insertBefore(element, nextElement);
        if(dropon.parentNode!=oldParentNode) 
          Sortable.options(oldParentNode).onChange(element);
        Sortable.options(dropon.parentNode).onChange(element);
      }
    }
  },
  
  onEmptyHover: function(element, dropon, overlap) {
    var oldParentNode = element.parentNode;
    var droponOptions = Sortable.options(dropon);
        
    if(!Element.isParent(dropon, element)) {
      var index;
      
      var children = Sortable.findElements(dropon, {tag: droponOptions.tag, only: droponOptions.only});
      var child = null;
            
      if(children) {
        var offset = Element.offsetSize(dropon, droponOptions.overlap) * (1.0 - overlap);
        
        for (index = 0; index < children.length; index += 1) {
          if (offset - Element.offsetSize (children[index], droponOptions.overlap) >= 0) {
            offset -= Element.offsetSize (children[index], droponOptions.overlap);
          } else if (offset - (Element.offsetSize (children[index], droponOptions.overlap) / 2) >= 0) {
            child = index + 1 < children.length ? children[index + 1] : null;
            break;
          } else {
            child = children[index];
            break;
          }
        }
      }
      
      dropon.insertBefore(element, child);
      
      Sortable.options(oldParentNode).onChange(element);
      droponOptions.onChange(element);
    }
  },

  unmark: function() {
    if(Sortable._marker) Sortable._marker.hide();
  },

  mark: function(dropon, position) {
    // mark on ghosting only
    var sortable = Sortable.options(dropon.parentNode);
    if(sortable && !sortable.ghosting) return; 

    if(!Sortable._marker) {
      Sortable._marker = 
        ($('dropmarker') || Element.extend(document.createElement('DIV'))).
          hide().addClassName('dropmarker').setStyle({position:'absolute'});
      document.getElementsByTagName("body").item(0).appendChild(Sortable._marker);
    }    
    var offsets = Position.cumulativeOffset(dropon);
    Sortable._marker.setStyle({left: offsets[0]+'px', top: offsets[1] + 'px'});
    
    if(position=='after')
      if(sortable.overlap == 'horizontal') 
        Sortable._marker.setStyle({left: (offsets[0]+dropon.clientWidth) + 'px'});
      else
        Sortable._marker.setStyle({top: (offsets[1]+dropon.clientHeight) + 'px'});
    
    Sortable._marker.show();
  },
  
  _tree: function(element, options, parent) {
    var children = Sortable.findElements(element, options) || [];
  
    for (var i = 0; i < children.length; ++i) {
      var match = children[i].id.match(options.format);

      if (!match) continue;
      
      var child = {
        id: encodeURIComponent(match ? match[1] : null),
        element: element,
        parent: parent,
        children: [],
        position: parent.children.length,
        container: $(children[i]).down(options.treeTag)
      }
      
      /* Get the element containing the children and recurse over it */
      if (child.container)
        this._tree(child.container, options, child)
      
      parent.children.push (child);
    }

    return parent; 
  },

  tree: function(element) {
    element = $(element);
    var sortableOptions = this.options(element);
    var options = Object.extend({
      tag: sortableOptions.tag,
      treeTag: sortableOptions.treeTag,
      only: sortableOptions.only,
      name: element.id,
      format: sortableOptions.format
    }, arguments[1] || { });
    
    var root = {
      id: null,
      parent: null,
      children: [],
      container: element,
      position: 0
    }
    
    return Sortable._tree(element, options, root);
  },

  /* Construct a [i] index for a particular node */
  _constructIndex: function(node) {
    var index = '';
    do {
      if (node.id) index = '[' + node.position + ']' + index;
    } while ((node = node.parent) != null);
    return index;
  },

  sequence: function(element) {
    element = $(element);
    var options = Object.extend(this.options(element), arguments[1] || { });
    
    return $(this.findElements(element, options) || []).map( function(item) {
      return item.id.match(options.format) ? item.id.match(options.format)[1] : '';
    });
  },

  setSequence: function(element, new_sequence) {
    element = $(element);
    var options = Object.extend(this.options(element), arguments[2] || { });
    
    var nodeMap = { };
    this.findElements(element, options).each( function(n) {
        if (n.id.match(options.format))
            nodeMap[n.id.match(options.format)[1]] = [n, n.parentNode];
        n.parentNode.removeChild(n);
    });
   
    new_sequence.each(function(ident) {
      var n = nodeMap[ident];
      if (n) {
        n[1].appendChild(n[0]);
        delete nodeMap[ident];
      }
    });
  },
  
  serialize: function(element) {
    element = $(element);
    var options = Object.extend(Sortable.options(element), arguments[1] || { });
    var name = encodeURIComponent(
      (arguments[1] && arguments[1].name) ? arguments[1].name : element.id);
    
    if (options.tree) {
      return Sortable.tree(element, arguments[1]).children.map( function (item) {
        return [name + Sortable._constructIndex(item) + "[id]=" + 
                encodeURIComponent(item.id)].concat(item.children.map(arguments.callee));
      }).flatten().join('&');
    } else {
      return Sortable.sequence(element, arguments[1]).map( function(item) {
        return name + "[]=" + encodeURIComponent(item);
      }).join('&');
    }
  }
}

// Returns true if child is contained within element
Element.isParent = function(child, element) {
  if (!child.parentNode || child == element) return false;
  if (child.parentNode == element) return true;
  return Element.isParent(child.parentNode, element);
}

Element.findChildren = function(element, only, recursive, tagName) {   
  if(!element.hasChildNodes()) return null;
  tagName = tagName.toUpperCase();
  if(only) only = [only].flatten();
  var elements = [];
  $A(element.childNodes).each( function(e) {
    if(e.tagName && e.tagName.toUpperCase()==tagName &&
      (!only || (Element.classNames(e).detect(function(v) { return only.include(v) }))))
        elements.push(e);
    if(recursive) {
      var grandchildren = Element.findChildren(e, only, recursive, tagName);
      if(grandchildren) elements.push(grandchildren);
    }
  });

  return (elements.length>0 ? elements.flatten() : []);
}

Element.offsetSize = function (element, type) {
  return element['offset' + ((type=='vertical' || type=='height') ? 'Height' : 'Width')];
}


// Copyright (c) 2005-2008 Thomas Fuchs (http://script.aculo.us, http://mir.aculo.us)
//           (c) 2005-2007 Ivan Krstic (http://blogs.law.harvard.edu/ivan)
//           (c) 2005-2007 Jon Tirsen (http://www.tirsen.com)
// Contributors:
//  Richard Livsey
//  Rahul Bhargava
//  Rob Wills
// 
// script.aculo.us is freely distributable under the terms of an MIT-style license.
// For details, see the script.aculo.us web site: http://script.aculo.us/

// Autocompleter.Base handles all the autocompletion functionality 
// that's independent of the data source for autocompletion. This
// includes drawing the autocompletion menu, observing keyboard
// and mouse events, and similar.
//
// Specific autocompleters need to provide, at the very least, 
// a getUpdatedChoices function that will be invoked every time
// the text inside the monitored textbox changes. This method 
// should get the text for which to provide autocompletion by
// invoking this.getToken(), NOT by directly accessing
// this.element.value. This is to allow incremental tokenized
// autocompletion. Specific auto-completion logic (AJAX, etc)
// belongs in getUpdatedChoices.
//
// Tokenized incremental autocompletion is enabled automatically
// when an autocompleter is instantiated with the 'tokens' option
// in the options parameter, e.g.:
// new Ajax.Autocompleter('id','upd', '/url/', { tokens: ',' });
// will incrementally autocomplete with a comma as the token.
// Additionally, ',' in the above example can be replaced with
// a token array, e.g. { tokens: [',', '\n'] } which
// enables autocompletion on multiple tokens. This is most 
// useful when one of the tokens is \n (a newline), as it 
// allows smart autocompletion after linebreaks.

if(typeof Effect == 'undefined')
  throw("controls.js requires including script.aculo.us' effects.js library");

var Autocompleter = { }
Autocompleter.Base = Class.create({
  baseInitialize: function(element, update, options) {
    element          = $(element)
    this.element     = element; 
    this.update      = $(update);  
    this.hasFocus    = false; 
    this.changed     = false; 
    this.active      = false; 
    this.index       = 0;     
    this.entryCount  = 0;
    this.oldElementValue = this.element.value;

    if(this.setOptions)
      this.setOptions(options);
    else
      this.options = options || { };

    this.options.paramName    = this.options.paramName || this.element.name;
    this.options.tokens       = this.options.tokens || [];
    this.options.frequency    = this.options.frequency || 0.4;
    this.options.minChars     = this.options.minChars || 1;
    this.options.onShow       = this.options.onShow || 
      function(element, update){ 
        if(!update.style.position || update.style.position=='absolute') {
          update.style.position = 'absolute';
          Position.clone(element, update, {
            setHeight: false, 
            offsetTop: element.offsetHeight
          });
        }
        Effect.Appear(update,{duration:0.15});
      };
    this.options.onHide = this.options.onHide || 
      function(element, update){ new Effect.Fade(update,{duration:0.15}) };

    if(typeof(this.options.tokens) == 'string') 
      this.options.tokens = new Array(this.options.tokens);
    // Force carriage returns as token delimiters anyway
    if (!this.options.tokens.include('\n'))
      this.options.tokens.push('\n');

    this.observer = null;
    
    this.element.setAttribute('autocomplete','off');

    Element.hide(this.update);

    Event.observe(this.element, 'blur', this.onBlur.bindAsEventListener(this));
    Event.observe(this.element, 'keydown', this.onKeyPress.bindAsEventListener(this));
  },

  show: function() {
    if(Element.getStyle(this.update, 'display')=='none') this.options.onShow(this.element, this.update);
    if(!this.iefix && 
      (Prototype.Browser.IE) &&
      (Element.getStyle(this.update, 'position')=='absolute')) {
      new Insertion.After(this.update, 
       '<iframe id="' + this.update.id + '_iefix" '+
       'style="display:none;position:absolute;filter:progid:DXImageTransform.Microsoft.Alpha(opacity=0);" ' +
       'src="javascript:false;" frameborder="0" scrolling="no"></iframe>');
      this.iefix = $(this.update.id+'_iefix');
    }
    if(this.iefix) setTimeout(this.fixIEOverlapping.bind(this), 50);
  },
  
  fixIEOverlapping: function() {
    Position.clone(this.update, this.iefix, {setTop:(!this.update.style.height)});
    this.iefix.style.zIndex = 1;
    this.update.style.zIndex = 2;
    Element.show(this.iefix);
  },

  hide: function() {
    this.stopIndicator();
    if(Element.getStyle(this.update, 'display')!='none') this.options.onHide(this.element, this.update);
    if(this.iefix) Element.hide(this.iefix);
  },

  startIndicator: function() {
    if(this.options.indicator) Element.show(this.options.indicator);
  },

  stopIndicator: function() {
    if(this.options.indicator) Element.hide(this.options.indicator);
  },

  onKeyPress: function(event) {
    if(this.active)
      switch(event.keyCode) {
       case Event.KEY_TAB:
       case Event.KEY_RETURN:
         this.selectEntry();
         Event.stop(event);
       case Event.KEY_ESC:
         this.hide();
         this.active = false;
         Event.stop(event);
         return;
       case Event.KEY_LEFT:
       case Event.KEY_RIGHT:
         return;
       case Event.KEY_UP:
         this.markPrevious();
         this.render();
         Event.stop(event);
         return;
       case Event.KEY_DOWN:
         this.markNext();
         this.render();
         Event.stop(event);
         return;
      }
     else 
       if(event.keyCode==Event.KEY_TAB || event.keyCode==Event.KEY_RETURN || 
         (Prototype.Browser.WebKit > 0 && event.keyCode == 0)) return;

    this.changed = true;
    this.hasFocus = true;

    if(this.observer) clearTimeout(this.observer);
      this.observer = 
        setTimeout(this.onObserverEvent.bind(this), this.options.frequency*1000);
  },

  activate: function() {
    this.changed = false;
    this.hasFocus = true;
    this.getUpdatedChoices();
  },

  onHover: function(event) {
    var element = Event.findElement(event, 'LI');
    if(this.index != element.autocompleteIndex) 
    {
        this.index = element.autocompleteIndex;
        this.render();
    }
    Event.stop(event);
  },
  
  onClick: function(event) {
    var element = Event.findElement(event, 'LI');
    this.index = element.autocompleteIndex;
    this.selectEntry();
    this.hide();
  },
  
  onBlur: function(event) {
    // needed to make click events working
    setTimeout(this.hide.bind(this), 250);
    this.hasFocus = false;
    this.active = false;     
  }, 
  
  render: function() {
    if(this.entryCount > 0) {
      for (var i = 0; i < this.entryCount; i++)
        this.index==i ? 
          Element.addClassName(this.getEntry(i),"selected") : 
          Element.removeClassName(this.getEntry(i),"selected");
      if(this.hasFocus) { 
        this.show();
        this.active = true;
      }
    } else {
      this.active = false;
      this.hide();
    }
  },
  
  markPrevious: function() {
    if(this.index > 0) this.index--
      else this.index = this.entryCount-1;
    this.getEntry(this.index).scrollIntoView(true);
  },
  
  markNext: function() {
    if(this.index < this.entryCount-1) this.index++
      else this.index = 0;
    this.getEntry(this.index).scrollIntoView(false);
  },
  
  getEntry: function(index) {
    return this.update.firstChild.childNodes[index];
  },
  
  getCurrentEntry: function() {
    return this.getEntry(this.index);
  },
  
  selectEntry: function() {
    this.active = false;
    this.updateElement(this.getCurrentEntry());
  },

  updateElement: function(selectedElement) {
    if (this.options.updateElement) {
      this.options.updateElement(selectedElement);
      return;
    }
    var value = '';
    if (this.options.select) {
      var nodes = $(selectedElement).select('.' + this.options.select) || [];
      if(nodes.length>0) value = Element.collectTextNodes(nodes[0], this.options.select);
    } else
      value = Element.collectTextNodesIgnoreClass(selectedElement, 'informal');
    
    var bounds = this.getTokenBounds();
    if (bounds[0] != -1) {
      var newValue = this.element.value.substr(0, bounds[0]);
      var whitespace = this.element.value.substr(bounds[0]).match(/^\s+/);
      if (whitespace)
        newValue += whitespace[0];
      this.element.value = newValue + value + this.element.value.substr(bounds[1]);
    } else {
      this.element.value = value;
    }
    this.oldElementValue = this.element.value;
    this.element.focus();
    
    if (this.options.afterUpdateElement)
      this.options.afterUpdateElement(this.element, selectedElement);
  },

  updateChoices: function(choices) {
    if(!this.changed && this.hasFocus) {
      this.update.innerHTML = choices;
      Element.cleanWhitespace(this.update);
      Element.cleanWhitespace(this.update.down());

      if(this.update.firstChild && this.update.down().childNodes) {
        this.entryCount = 
          this.update.down().childNodes.length;
        for (var i = 0; i < this.entryCount; i++) {
          var entry = this.getEntry(i);
          entry.autocompleteIndex = i;
          this.addObservers(entry);
        }
      } else { 
        this.entryCount = 0;
      }

      this.stopIndicator();
      this.index = 0;
      
      if(this.entryCount==1 && this.options.autoSelect) {
        this.selectEntry();
        this.hide();
      } else {
        this.render();
      }
    }
  },

  addObservers: function(element) {
    Event.observe(element, "mouseover", this.onHover.bindAsEventListener(this));
    Event.observe(element, "click", this.onClick.bindAsEventListener(this));
  },

  onObserverEvent: function() {
    this.changed = false;   
    this.tokenBounds = null;
    if(this.getToken().length>=this.options.minChars) {
      this.getUpdatedChoices();
    } else {
      this.active = false;
      this.hide();
    }
    this.oldElementValue = this.element.value;
  },

  getToken: function() {
    var bounds = this.getTokenBounds();
    return this.element.value.substring(bounds[0], bounds[1]).strip();
  },

  getTokenBounds: function() {
    if (null != this.tokenBounds) return this.tokenBounds;
    var value = this.element.value;
    if (value.strip().empty()) return [-1, 0];
    var diff = arguments.callee.getFirstDifferencePos(value, this.oldElementValue);
    var offset = (diff == this.oldElementValue.length ? 1 : 0);
    var prevTokenPos = -1, nextTokenPos = value.length;
    var tp;
    for (var index = 0, l = this.options.tokens.length; index < l; ++index) {
      tp = value.lastIndexOf(this.options.tokens[index], diff + offset - 1);
      if (tp > prevTokenPos) prevTokenPos = tp;
      tp = value.indexOf(this.options.tokens[index], diff + offset);
      if (-1 != tp && tp < nextTokenPos) nextTokenPos = tp;
    }
    return (this.tokenBounds = [prevTokenPos + 1, nextTokenPos]);
  }
});

Autocompleter.Base.prototype.getTokenBounds.getFirstDifferencePos = function(newS, oldS) {
  var boundary = Math.min(newS.length, oldS.length);
  for (var index = 0; index < boundary; ++index)
    if (newS[index] != oldS[index])
      return index;
  return boundary;
};

Ajax.Autocompleter = Class.create(Autocompleter.Base, {
  initialize: function(element, update, url, options) {
    this.baseInitialize(element, update, options);
    this.options.asynchronous  = true;
    this.options.onComplete    = this.onComplete.bind(this);
    this.options.defaultParams = this.options.parameters || null;
    this.url                   = url;
  },

  getUpdatedChoices: function() {
    this.startIndicator();
    
    var entry = encodeURIComponent(this.options.paramName) + '=' + 
      encodeURIComponent(this.getToken());

    this.options.parameters = this.options.callback ?
      this.options.callback(this.element, entry) : entry;

    if(this.options.defaultParams) 
      this.options.parameters += '&' + this.options.defaultParams;
    
    new Ajax.Request(this.url, this.options);
  },

  onComplete: function(request) {
    this.updateChoices(request.responseText);
  }
});

// The local array autocompleter. Used when you'd prefer to
// inject an array of autocompletion options into the page, rather
// than sending out Ajax queries, which can be quite slow sometimes.
//
// The constructor takes four parameters. The first two are, as usual,
// the id of the monitored textbox, and id of the autocompletion menu.
// The third is the array you want to autocomplete from, and the fourth
// is the options block.
//
// Extra local autocompletion options:
// - choices - How many autocompletion choices to offer
//
// - partialSearch - If false, the autocompleter will match entered
//                    text only at the beginning of strings in the 
//                    autocomplete array. Defaults to true, which will
//                    match text at the beginning of any *word* in the
//                    strings in the autocomplete array. If you want to
//                    search anywhere in the string, additionally set
//                    the option fullSearch to true (default: off).
//
// - fullSsearch - Search anywhere in autocomplete array strings.
//
// - partialChars - How many characters to enter before triggering
//                   a partial match (unlike minChars, which defines
//                   how many characters are required to do any match
//                   at all). Defaults to 2.
//
// - ignoreCase - Whether to ignore case when autocompleting.
//                 Defaults to true.
//
// It's possible to pass in a custom function as the 'selector' 
// option, if you prefer to write your own autocompletion logic.
// In that case, the other options above will not apply unless
// you support them.

Autocompleter.Local = Class.create(Autocompleter.Base, {
  initialize: function(element, update, array, options) {
    this.baseInitialize(element, update, options);
    this.options.array = array;
  },

  getUpdatedChoices: function() {
    this.updateChoices(this.options.selector(this));
  },

  setOptions: function(options) {
    this.options = Object.extend({
      choices: 10,
      partialSearch: true,
      partialChars: 2,
      ignoreCase: true,
      fullSearch: false,
      selector: function(instance) {
        var ret       = []; // Beginning matches
        var partial   = []; // Inside matches
        var entry     = instance.getToken();
        var count     = 0;

        for (var i = 0; i < instance.options.array.length &&  
          ret.length < instance.options.choices ; i++) { 

          var elem = instance.options.array[i];
          var foundPos = instance.options.ignoreCase ? 
            elem.toLowerCase().indexOf(entry.toLowerCase()) : 
            elem.indexOf(entry);

          while (foundPos != -1) {
            if (foundPos == 0 && elem.length != entry.length) { 
              ret.push("<li><strong>" + elem.substr(0, entry.length) + "</strong>" + 
                elem.substr(entry.length) + "</li>");
              break;
            } else if (entry.length >= instance.options.partialChars && 
              instance.options.partialSearch && foundPos != -1) {
              if (instance.options.fullSearch || /\s/.test(elem.substr(foundPos-1,1))) {
                partial.push("<li>" + elem.substr(0, foundPos) + "<strong>" +
                  elem.substr(foundPos, entry.length) + "</strong>" + elem.substr(
                  foundPos + entry.length) + "</li>");
                break;
              }
            }

            foundPos = instance.options.ignoreCase ? 
              elem.toLowerCase().indexOf(entry.toLowerCase(), foundPos + 1) : 
              elem.indexOf(entry, foundPos + 1);

          }
        }
        if (partial.length)
          ret = ret.concat(partial.slice(0, instance.options.choices - ret.length))
        return "<ul>" + ret.join('') + "</ul>";
      }
    }, options || { });
  }
});

// AJAX in-place editor and collection editor
// Full rewrite by Christophe Porteneuve <tdd@tddsworld.com> (April 2007).

// Use this if you notice weird scrolling problems on some browsers,
// the DOM might be a bit confused when this gets called so do this
// waits 1 ms (with setTimeout) until it does the activation
Field.scrollFreeActivate = function(field) {
  setTimeout(function() {
    Field.activate(field);
  }, 1);
}

Ajax.InPlaceEditor = Class.create({
  initialize: function(element, url, options) {
    this.url = url;
    this.element = element = $(element);
    this.prepareOptions();
    this._controls = { };
    arguments.callee.dealWithDeprecatedOptions(options); // DEPRECATION LAYER!!!
    Object.extend(this.options, options || { });
    if (!this.options.formId && this.element.id) {
      this.options.formId = this.element.id + '-inplaceeditor';
      if ($(this.options.formId))
        this.options.formId = '';
    }
    if (this.options.externalControl)
      this.options.externalControl = $(this.options.externalControl);
    if (!this.options.externalControl)
      this.options.externalControlOnly = false;
    this._originalBackground = this.element.getStyle('background-color') || 'transparent';
    this.element.title = this.options.clickToEditText;
    this._boundCancelHandler = this.handleFormCancellation.bind(this);
    this._boundComplete = (this.options.onComplete || Prototype.emptyFunction).bind(this);
    this._boundFailureHandler = this.handleAJAXFailure.bind(this);
    this._boundSubmitHandler = this.handleFormSubmission.bind(this);
    this._boundWrapperHandler = this.wrapUp.bind(this);
    this.registerListeners();
  },
  checkForEscapeOrReturn: function(e) {
    if (!this._editing || e.ctrlKey || e.altKey || e.shiftKey) return;
    if (Event.KEY_ESC == e.keyCode)
      this.handleFormCancellation(e);
    else if (Event.KEY_RETURN == e.keyCode)
      this.handleFormSubmission(e);
  },
  createControl: function(mode, handler, extraClasses) {
    var control = this.options[mode + 'Control'];
    var text = this.options[mode + 'Text'];
    if ('button' == control) {
      var btn = document.createElement('input');
      btn.type = 'submit';
      btn.value = text;
      btn.className = 'editor_' + mode + '_button';
      if ('cancel' == mode)
        btn.onclick = this._boundCancelHandler;
      this._form.appendChild(btn);
      this._controls[mode] = btn;
    } else if ('link' == control) {
      var link = document.createElement('a');
      link.href = '#';
      link.appendChild(document.createTextNode(text));
      link.onclick = 'cancel' == mode ? this._boundCancelHandler : this._boundSubmitHandler;
      link.className = 'editor_' + mode + '_link';
      if (extraClasses)
        link.className += ' ' + extraClasses;
      this._form.appendChild(link);
      this._controls[mode] = link;
    }
  },
  createEditField: function() {
    var text = (this.options.loadTextURL ? this.options.loadingText : this.getText());
    var fld;
    if (1 >= this.options.rows && !/\r|\n/.test(this.getText())) {
      fld = document.createElement('input');
      fld.type = 'text';
      var size = this.options.size || this.options.cols || 0;
      if (0 < size) fld.size = size;
    } else {
      fld = document.createElement('textarea');
      fld.rows = (1 >= this.options.rows ? this.options.autoRows : this.options.rows);
      fld.cols = this.options.cols || 40;
    }
    fld.name = this.options.paramName;
    fld.value = text; // No HTML breaks conversion anymore
    fld.className = 'editor_field';
    if (this.options.submitOnBlur)
      fld.onblur = this._boundSubmitHandler;
    this._controls.editor = fld;
    if (this.options.loadTextURL)
      this.loadExternalText();
    this._form.appendChild(this._controls.editor);
  },
  createForm: function() {
    var ipe = this;
    function addText(mode, condition) {
      var text = ipe.options['text' + mode + 'Controls'];
      if (!text || condition === false) return;
      ipe._form.appendChild(document.createTextNode(text));
    };
    this._form = $(document.createElement('form'));
    this._form.id = this.options.formId;
    this._form.addClassName(this.options.formClassName);
    this._form.onsubmit = this._boundSubmitHandler;
    this.createEditField();
    if ('textarea' == this._controls.editor.tagName.toLowerCase())
      this._form.appendChild(document.createElement('br'));
    if (this.options.onFormCustomization)
      this.options.onFormCustomization(this, this._form);
    addText('Before', this.options.okControl || this.options.cancelControl);
    this.createControl('ok', this._boundSubmitHandler);
    addText('Between', this.options.okControl && this.options.cancelControl);
    this.createControl('cancel', this._boundCancelHandler, 'editor_cancel');
    addText('After', this.options.okControl || this.options.cancelControl);
  },
  destroy: function() {
    if (this._oldInnerHTML)
      this.element.innerHTML = this._oldInnerHTML;
    this.leaveEditMode();
    this.unregisterListeners();
  },
  enterEditMode: function(e) {
    if (this._saving || this._editing) return;
    this._editing = true;
    this.triggerCallback('onEnterEditMode');
    if (this.options.externalControl)
      this.options.externalControl.hide();
    this.element.hide();
    this.createForm();
    this.element.parentNode.insertBefore(this._form, this.element);
    if (!this.options.loadTextURL)
      this.postProcessEditField();
    if (e) Event.stop(e);
  },
  enterHover: function(e) {
    if (this.options.hoverClassName)
      this.element.addClassName(this.options.hoverClassName);
    if (this._saving) return;
    this.triggerCallback('onEnterHover');
  },
  getText: function() {
    return this.element.innerHTML;
  },
  handleAJAXFailure: function(transport) {
    this.triggerCallback('onFailure', transport);
    if (this._oldInnerHTML) {
      this.element.innerHTML = this._oldInnerHTML;
      this._oldInnerHTML = null;
    }
  },
  handleFormCancellation: function(e) {
    this.wrapUp();
    if (e) Event.stop(e);
  },
  handleFormSubmission: function(e) {
    var form = this._form;
    var value = $F(this._controls.editor);
    this.prepareSubmission();
    var params = this.options.callback(form, value) || '';
    if (Object.isString(params))
      params = params.toQueryParams();
    params.editorId = this.element.id;
    if (this.options.htmlResponse) {
      var options = Object.extend({ evalScripts: true }, this.options.ajaxOptions);
      Object.extend(options, {
        parameters: params,
        onComplete: this._boundWrapperHandler,
        onFailure: this._boundFailureHandler
      });
      new Ajax.Updater({ success: this.element }, this.url, options);
    } else {
      var options = Object.extend({ method: 'get' }, this.options.ajaxOptions);
      Object.extend(options, {
        parameters: params,
        onComplete: this._boundWrapperHandler,
        onFailure: this._boundFailureHandler
      });
      new Ajax.Request(this.url, options);
    }
    if (e) Event.stop(e);
  },
  leaveEditMode: function() {
    this.element.removeClassName(this.options.savingClassName);
    this.removeForm();
    this.leaveHover();
    this.element.style.backgroundColor = this._originalBackground;
    this.element.show();
    if (this.options.externalControl)
      this.options.externalControl.show();
    this._saving = false;
    this._editing = false;
    this._oldInnerHTML = null;
    this.triggerCallback('onLeaveEditMode');
  },
  leaveHover: function(e) {
    if (this.options.hoverClassName)
      this.element.removeClassName(this.options.hoverClassName);
    if (this._saving) return;
    this.triggerCallback('onLeaveHover');
  },
  loadExternalText: function() {
    this._form.addClassName(this.options.loadingClassName);
    this._controls.editor.disabled = true;
    var options = Object.extend({ method: 'get' }, this.options.ajaxOptions);
    Object.extend(options, {
      parameters: 'editorId=' + encodeURIComponent(this.element.id),
      onComplete: Prototype.emptyFunction,
      onSuccess: function(transport) {
        this._form.removeClassName(this.options.loadingClassName);
        var text = transport.responseText;
        if (this.options.stripLoadedTextTags)
          text = text.stripTags();
        this._controls.editor.value = text;
        this._controls.editor.disabled = false;
        this.postProcessEditField();
      }.bind(this),
      onFailure: this._boundFailureHandler
    });
    new Ajax.Request(this.options.loadTextURL, options);
  },
  postProcessEditField: function() {
    var fpc = this.options.fieldPostCreation;
    if (fpc)
      $(this._controls.editor)['focus' == fpc ? 'focus' : 'activate']();
  },
  prepareOptions: function() {
    this.options = Object.clone(Ajax.InPlaceEditor.DefaultOptions);
    Object.extend(this.options, Ajax.InPlaceEditor.DefaultCallbacks);
    [this._extraDefaultOptions].flatten().compact().each(function(defs) {
      Object.extend(this.options, defs);
    }.bind(this));
  },
  prepareSubmission: function() {
    this._saving = true;
    this.removeForm();
    this.leaveHover();
    this.showSaving();
  },
  registerListeners: function() {
    this._listeners = { };
    var listener;
    $H(Ajax.InPlaceEditor.Listeners).each(function(pair) {
      listener = this[pair.value].bind(this);
      this._listeners[pair.key] = listener;
      if (!this.options.externalControlOnly)
        this.element.observe(pair.key, listener);
      if (this.options.externalControl)
        this.options.externalControl.observe(pair.key, listener);
    }.bind(this));
  },
  removeForm: function() {
    if (!this._form) return;
    this._form.remove();
    this._form = null;
    this._controls = { };
  },
  showSaving: function() {
    this._oldInnerHTML = this.element.innerHTML;
    this.element.innerHTML = this.options.savingText;
    this.element.addClassName(this.options.savingClassName);
    this.element.style.backgroundColor = this._originalBackground;
    this.element.show();
  },
  triggerCallback: function(cbName, arg) {
    if ('function' == typeof this.options[cbName]) {
      this.options[cbName](this, arg);
    }
  },
  unregisterListeners: function() {
    $H(this._listeners).each(function(pair) {
      if (!this.options.externalControlOnly)
        this.element.stopObserving(pair.key, pair.value);
      if (this.options.externalControl)
        this.options.externalControl.stopObserving(pair.key, pair.value);
    }.bind(this));
  },
  wrapUp: function(transport) {
    this.leaveEditMode();
    // Can't use triggerCallback due to backward compatibility: requires
    // binding + direct element
    this._boundComplete(transport, this.element);
  }
});

Object.extend(Ajax.InPlaceEditor.prototype, {
  dispose: Ajax.InPlaceEditor.prototype.destroy
});

Ajax.InPlaceCollectionEditor = Class.create(Ajax.InPlaceEditor, {
  initialize: function($super, element, url, options) {
    this._extraDefaultOptions = Ajax.InPlaceCollectionEditor.DefaultOptions;
    $super(element, url, options);
  },

  createEditField: function() {
    var list = document.createElement('select');
    list.name = this.options.paramName;
    list.size = 1;
    this._controls.editor = list;
    this._collection = this.options.collection || [];
    if (this.options.loadCollectionURL)
      this.loadCollection();
    else
      this.checkForExternalText();
    this._form.appendChild(this._controls.editor);
  },

  loadCollection: function() {
    this._form.addClassName(this.options.loadingClassName);
    this.showLoadingText(this.options.loadingCollectionText);
    var options = Object.extend({ method: 'get' }, this.options.ajaxOptions);
    Object.extend(options, {
      parameters: 'editorId=' + encodeURIComponent(this.element.id),
      onComplete: Prototype.emptyFunction,
      onSuccess: function(transport) {
        var js = transport.responseText.strip();
        if (!/^\[.*\]$/.test(js)) // TODO: improve sanity check
          throw 'Server returned an invalid collection representation.';
        this._collection = eval(js);
        this.checkForExternalText();
      }.bind(this),
      onFailure: this.onFailure
    });
    new Ajax.Request(this.options.loadCollectionURL, options);
  },

  showLoadingText: function(text) {
    this._controls.editor.disabled = true;
    var tempOption = this._controls.editor.firstChild;
    if (!tempOption) {
      tempOption = document.createElement('option');
      tempOption.value = '';
      this._controls.editor.appendChild(tempOption);
      tempOption.selected = true;
    }
    tempOption.update((text || '').stripScripts().stripTags());
  },

  checkForExternalText: function() {
    this._text = this.getText();
    if (this.options.loadTextURL)
      this.loadExternalText();
    else
      this.buildOptionList();
  },

  loadExternalText: function() {
    this.showLoadingText(this.options.loadingText);
    var options = Object.extend({ method: 'get' }, this.options.ajaxOptions);
    Object.extend(options, {
      parameters: 'editorId=' + encodeURIComponent(this.element.id),
      onComplete: Prototype.emptyFunction,
      onSuccess: function(transport) {
        this._text = transport.responseText.strip();
        this.buildOptionList();
      }.bind(this),
      onFailure: this.onFailure
    });
    new Ajax.Request(this.options.loadTextURL, options);
  },

  buildOptionList: function() {
    this._form.removeClassName(this.options.loadingClassName);
    this._collection = this._collection.map(function(entry) {
      return 2 === entry.length ? entry : [entry, entry].flatten();
    });
    var marker = ('value' in this.options) ? this.options.value : this._text;
    var textFound = this._collection.any(function(entry) {
      return entry[0] == marker;
    }.bind(this));
    this._controls.editor.update('');
    var option;
    this._collection.each(function(entry, index) {
      option = document.createElement('option');
      option.value = entry[0];
      option.selected = textFound ? entry[0] == marker : 0 == index;
      option.appendChild(document.createTextNode(entry[1]));
      this._controls.editor.appendChild(option);
    }.bind(this));
    this._controls.editor.disabled = false;
    Field.scrollFreeActivate(this._controls.editor);
  }
});

//**** DEPRECATION LAYER FOR InPlace[Collection]Editor! ****
//**** This only  exists for a while,  in order to  let ****
//**** users adapt to  the new API.  Read up on the new ****
//**** API and convert your code to it ASAP!            ****

Ajax.InPlaceEditor.prototype.initialize.dealWithDeprecatedOptions = function(options) {
  if (!options) return;
  function fallback(name, expr) {
    if (name in options || expr === undefined) return;
    options[name] = expr;
  };
  fallback('cancelControl', (options.cancelLink ? 'link' : (options.cancelButton ? 'button' :
    options.cancelLink == options.cancelButton == false ? false : undefined)));
  fallback('okControl', (options.okLink ? 'link' : (options.okButton ? 'button' :
    options.okLink == options.okButton == false ? false : undefined)));
  fallback('highlightColor', options.highlightcolor);
  fallback('highlightEndColor', options.highlightendcolor);
};

Object.extend(Ajax.InPlaceEditor, {
  DefaultOptions: {
    ajaxOptions: { },
    autoRows: 3,                                // Use when multi-line w/ rows == 1
    cancelControl: 'link',                      // 'link'|'button'|false
    cancelText: 'cancel',
    clickToEditText: 'Click to edit',
    externalControl: null,                      // id|elt
    externalControlOnly: false,
    fieldPostCreation: 'activate',              // 'activate'|'focus'|false
    formClassName: 'inplaceeditor-form',
    formId: null,                               // id|elt
    highlightColor: '#ffff99',
    highlightEndColor: '#ffffff',
    hoverClassName: '',
    htmlResponse: true,
    loadingClassName: 'inplaceeditor-loading',
    loadingText: 'Loading...',
    okControl: 'button',                        // 'link'|'button'|false
    okText: 'ok',
    paramName: 'value',
    rows: 1,                                    // If 1 and multi-line, uses autoRows
    savingClassName: 'inplaceeditor-saving',
    savingText: 'Saving...',
    size: 0,
    stripLoadedTextTags: false,
    submitOnBlur: false,
    textAfterControls: '',
    textBeforeControls: '',
    textBetweenControls: ''
  },
  DefaultCallbacks: {
    callback: function(form) {
      return Form.serialize(form);
    },
    onComplete: function(transport, element) {
      // For backward compatibility, this one is bound to the IPE, and passes
      // the element directly.  It was too often customized, so we don't break it.
      new Effect.Highlight(element, {
        startcolor: this.options.highlightColor, keepBackgroundImage: true });
    },
    onEnterEditMode: null,
    onEnterHover: function(ipe) {
      ipe.element.style.backgroundColor = ipe.options.highlightColor;
      if (ipe._effect)
        ipe._effect.cancel();
    },
    onFailure: function(transport, ipe) {
      alert('Error communication with the server: ' + transport.responseText.stripTags());
    },
    onFormCustomization: null, // Takes the IPE and its generated form, after editor, before controls.
    onLeaveEditMode: null,
    onLeaveHover: function(ipe) {
      ipe._effect = new Effect.Highlight(ipe.element, {
        startcolor: ipe.options.highlightColor, endcolor: ipe.options.highlightEndColor,
        restorecolor: ipe._originalBackground, keepBackgroundImage: true
      });
    }
  },
  Listeners: {
    click: 'enterEditMode',
    keydown: 'checkForEscapeOrReturn',
    mouseover: 'enterHover',
    mouseout: 'leaveHover'
  }
});

Ajax.InPlaceCollectionEditor.DefaultOptions = {
  loadingCollectionText: 'Loading options...'
};

// Delayed observer, like Form.Element.Observer, 
// but waits for delay after last key input
// Ideal for live-search fields

Form.Element.DelayedObserver = Class.create({
  initialize: function(element, delay, callback) {
    this.delay     = delay || 0.5;
    this.element   = $(element);
    this.callback  = callback;
    this.timer     = null;
    this.lastValue = $F(this.element); 
    Event.observe(this.element,'keyup',this.delayedListener.bindAsEventListener(this));
  },
  delayedListener: function(event) {
    if(this.lastValue == $F(this.element)) return;
    if(this.timer) clearTimeout(this.timer);
    this.timer = setTimeout(this.onTimerEvent.bind(this), this.delay * 1000);
    this.lastValue = $F(this.element);
  },
  onTimerEvent: function() {
    this.timer = null;
    this.callback(this.element, $F(this.element));
  }
});


// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

