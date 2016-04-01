$( document ).ready(function() {
  $('#datepicker.input-daterange').datepicker({
    format: "yyyy-mm-dd",
    weekStart: 1,
    clearBtn: true,
    autoclose: true,
    todayHighlight: true
  });
});
