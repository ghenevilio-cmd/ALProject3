TBGC Receiving UI workspace

This folder is reserved for the new Receiving UI objects in Business Central.

Planned purpose:
- show receiving purchase orders based on the assigned retail user
- allow users to check whether they have pending receiving POs
- keep receiving-related AL objects separate from TBGC Brandcode

Related frontend folder:
- `src/ReactBC-main/react-receiving`

Suggested check flow:
- AL host/control add-in files stay in this folder
- React UI/build files stay in `react-receiving`
