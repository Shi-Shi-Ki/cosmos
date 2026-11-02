function onOpen() {
  const ui = SpreadsheetApp.getUi();
  ui.createMenu("Tools").addItem("Run", "run").addToUi();
}
