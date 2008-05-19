// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// for compatibility issuses in jQuery and Rails
//
//jQuery.ajaxSetup({ 
//  'beforeSend': function(xhr) {
//    xhr.setRequestHeader("Accept", "text/javascript")
//  } 
//})

// helper functions for Ajaxifying standard links and forms, and evaluating returned Javascript
//$(function() {
//  $("a.rjs").click( function() {
//    $.ajax({
//        url: this.href,
//        dataType: "script",
//        beforeSend: function(xhr) {xhr.setRequestHeader("Accept", "text/javascript");}
//    });
//    return false;
//  });
//  // requires jQuery.form plugin
//  $("form.rjs").ajaxForm({
//    dataType: 'script',
//    beforeSend: function(xhr) {xhr.setRequestHeader("Accept", "text/javascript");},
//    resetForm: true
//  });
//});
