$(document).on('turbolinks:load', function() {

  //Merge all editor components.
  $.extend(
      CodeOceanEditor,
      CodeOceanEditorAJAX,
      CodeOceanEditorEvaluation,
      CodeOceanEditorFlowr,
      CodeOceanEditorSubmissions,
      CodeOceanEditorTurtle,
      CodeOceanEditorWebsocket,
      CodeOceanEditorPrompt,
      CodeOceanEditorCodePilot,
      CodeOceanEditorRequestForComments
  );

  if ($('#editor').isPresent() && CodeOceanEditor) {
    if (CodeOceanEditor.isBrowserSupported()) {
      CodeOceanEditor.initializeEverything();
    } else {
      $('#alert').show();
    }
  }
});
