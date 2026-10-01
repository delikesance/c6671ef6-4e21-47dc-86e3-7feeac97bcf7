import 'function_suite.dart';

/// Contracts inspect the same builders used for real Discord serialization.
const sandboxComponentFunctionCases = [
  SandboxFunctionCase(
    'addbutton',
    r'$addButton[no;press;((opts.label));primary;((opts.disabled))]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'label': 'Click', 'disabled': true},
    },
    expectedValues: {
      '/responses/0/api_components/0/components/0/label': 'Click',
      '/responses/0/api_components/0/components/0/disabled': true,
      '/responses/0/api_components/0/components/0/custom_id': 'press',
    },
  ),
  SandboxFunctionCase(
    'addbuttoncv2',
    r'$addButtonCV2[press;((opts.label));success;((opts.disabled))]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'label': 'Click', 'disabled': true},
    },
    expectedValues: {
      '/responses/0/api_components/0/components/0/style': 3,
      '/responses/0/api_components/0/components/0/disabled': true,
    },
  ),
  SandboxFunctionCase(
    'addbutton',
    r'$addButton[no;((opts.url));Link;((opts.Style));false]',
    0,
    '',
    label: 'dynamic link style',
    scenario: {
      'options': {'url': 'https://example.com', 'Style': 'link'},
    },
    expectedValues: {
      '/responses/0/api_components/0/components/0/style': 5,
      '/responses/0/api_components/0/components/0/url': 'https://example.com',
    },
  ),
  SandboxFunctionCase(
    'addactionrow',
    r'$addButtonCV2[first;One;primary;false]$addActionRow$addButtonCV2[second;Two;primary;false]',
    0,
    '',
    label: 'explicit row',
    scenario: {'options': {}},
    expectedValues: {
      '/responses/0/api_components/1/components/0/custom_id': 'second',
    },
  ),
  SandboxFunctionCase(
    'adduserselect',
    r'$adduserselect[menu;Choose;((opts.min));((opts.max));((opts.disabled))]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'min': 2, 'max': 3, 'disabled': true},
    },
    expectedValues: {
      '/responses/0/api_components/0/components/0/type': 5,
      '/responses/0/api_components/0/components/0/min_values': 2,
      '/responses/0/api_components/0/components/0/max_values': 3,
      '/responses/0/api_components/0/components/0/disabled': true,
    },
  ),
  SandboxFunctionCase(
    'addroleselect',
    r'$addroleselect[menu;Choose;((opts.min));((opts.max));((opts.disabled))]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'min': 2, 'max': 3, 'disabled': true},
    },
    expectedValues: {
      '/responses/0/api_components/0/components/0/type': 6,
      '/responses/0/api_components/0/components/0/min_values': 2,
      '/responses/0/api_components/0/components/0/max_values': 3,
      '/responses/0/api_components/0/components/0/disabled': true,
    },
  ),
  SandboxFunctionCase(
    'addmentionableselect',
    r'$addmentionableselect[menu;Choose;((opts.min));((opts.max));((opts.disabled))]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'min': 2, 'max': 3, 'disabled': true},
    },
    expectedValues: {
      '/responses/0/api_components/0/components/0/type': 7,
      '/responses/0/api_components/0/components/0/min_values': 2,
      '/responses/0/api_components/0/components/0/max_values': 3,
      '/responses/0/api_components/0/components/0/disabled': true,
    },
  ),
  SandboxFunctionCase(
    'addchannelselect',
    r'$addchannelselect[menu;Choose;((opts.min));((opts.max));((opts.disabled))]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'min': 2, 'max': 3, 'disabled': true},
    },
    expectedValues: {
      '/responses/0/api_components/0/components/0/type': 8,
      '/responses/0/api_components/0/components/0/min_values': 2,
      '/responses/0/api_components/0/components/0/max_values': 3,
      '/responses/0/api_components/0/components/0/disabled': true,
    },
  ),
  SandboxFunctionCase(
    'addcategoryselect',
    r'$addcategoryselect[menu;Choose;((opts.min));((opts.max));((opts.disabled))]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'min': 2, 'max': 3, 'disabled': true},
    },
    expectedValues: {
      '/responses/0/api_components/0/components/0/type': 8,
      '/responses/0/api_components/0/components/0/min_values': 2,
      '/responses/0/api_components/0/components/0/max_values': 3,
      '/responses/0/api_components/0/components/0/disabled': true,
      '/responses/0/api_components/0/components/0/channel_types': [4],
    },
  ),
  SandboxFunctionCase(
    'addvoiceselect',
    r'$addvoiceselect[menu;Choose;((opts.min));((opts.max));((opts.disabled))]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'min': 2, 'max': 3, 'disabled': true},
    },
    expectedValues: {
      '/responses/0/api_components/0/components/0/type': 8,
      '/responses/0/api_components/0/components/0/min_values': 2,
      '/responses/0/api_components/0/components/0/max_values': 3,
      '/responses/0/api_components/0/components/0/disabled': true,
      '/responses/0/api_components/0/components/0/channel_types': [2],
    },
  ),
  SandboxFunctionCase(
    'addstringselect',
    r'$addstringselect[menu;Choose;((opts.min));((opts.max));((opts.disabled))]$addStringSelectOption[One;one;;;true]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'min': 2, 'max': 3, 'disabled': true},
    },
    expectedValues: {
      '/responses/0/api_components/0/components/0/type': 3,
      '/responses/0/api_components/0/components/0/min_values': 2,
      '/responses/0/api_components/0/components/0/max_values': 3,
      '/responses/0/api_components/0/components/0/disabled': true,
    },
  ),
  SandboxFunctionCase(
    'newselectmenu',
    r'$newSelectMenu[menu;((opts.min));((opts.max));Choose]$addSelectMenuOption[menu;One;one;;true]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'min': 0, 'max': 2},
    },
    expectedValues: {
      '/responses/0/api_components/0/components/0/type': 3,
      '/responses/0/api_components/0/components/0/min_values': 0,
      '/responses/0/api_components/0/components/0/max_values': 2,
      '/responses/0/api_components/0/components/0/options/0/default': true,
    },
  ),
  SandboxFunctionCase(
    'addselectmenuoption',
    r'$newSelectMenu[menu;1;1;Choose]$addSelectMenuOption[menu;((opts.label));one;First choice;((opts.selected))]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'label': 'One', 'selected': true},
    },
    expectedValues: {
      '/responses/0/api_components/0/components/0/options/0/label': 'One',
      '/responses/0/api_components/0/components/0/options/0/default': true,
    },
  ),
  SandboxFunctionCase(
    'addstringselectoption',
    r'$addStringSelect[menu;Choose;1;1;false]$addStringSelectOption[One;one;First choice;;((opts.selected))]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'selected': true},
    },
    expectedValues: {
      '/responses/0/api_components/0/components/0/options/0/default': true,
    },
  ),
  SandboxFunctionCase(
    'editbutton',
    r'$addButton[no;press;Old;primary;false]$editButton[press;New;danger;((opts.disabled))]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'disabled': true},
    },
    expectedValues: {
      '/responses/0/api_components/0/components/0/label': 'New',
      '/responses/0/api_components/0/components/0/style': 4,
      '/responses/0/api_components/0/components/0/disabled': true,
    },
  ),
  SandboxFunctionCase(
    'editselectmenu',
    r'$newSelectMenu[menu;1;1;Old]$addSelectMenuOption[menu;One;one]$editSelectMenu[menu;((opts.min));((opts.max));New]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'min': 0, 'max': 2},
    },
    expectedValues: {
      '/responses/0/api_components/0/components/0/min_values': 0,
      '/responses/0/api_components/0/components/0/max_values': 2,
      '/responses/0/api_components/0/components/0/placeholder': 'New',
    },
  ),
  SandboxFunctionCase(
    'editselectmenuoption',
    r'$newSelectMenu[menu;1;1;Choose]$addSelectMenuOption[menu;Old;old]$editSelectMenuOption[menu;New;new;Description;((opts.selected))]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'selected': true},
    },
    expectedValues: {
      '/responses/0/api_components/0/components/0/options/0/label': 'New',
      '/responses/0/api_components/0/components/0/options/0/value': 'new',
      '/responses/0/api_components/0/components/0/options/0/default': true,
    },
  ),
  SandboxFunctionCase(
    'addselectmenuoption',
    r'$newSelectMenu[first;1;1;First]$newSelectMenu[second;1;1;Second]$addSelectMenuOption[first;One;one]$addSelectMenuOption[second;Two;two]',
    0,
    '',
    label: 'target earlier menu',
    scenario: {'options': {}},
    expectedValues: {
      '/responses/0/api_components/0/components/0/options/0/value': 'one',
      '/responses/0/api_components/1/components/0/options/0/value': 'two',
    },
  ),
  SandboxFunctionCase(
    'addtextdisplay',
    r'$addTextDisplay[((opts.text))]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'text': 'Hello'},
    },
    expectedValues: {
      '/responses/0/api_components/0/type': 10,
      '/responses/0/api_components/0/content': 'Hello',
    },
  ),
  SandboxFunctionCase(
    'addseparator',
    r'$addSeparator[((opts.divider));((opts.spacing))]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'divider': true, 'spacing': 2},
    },
    expectedValues: {
      '/responses/0/api_components/0/type': 14,
      '/responses/0/api_components/0/divider': true,
      '/responses/0/api_components/0/spacing': 2,
    },
  ),
  SandboxFunctionCase(
    'addcontainer',
    r'$addContainer[card;#00ff00;((opts.spoiler))]$addTextDisplay[Hello]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'spoiler': true},
    },
    expectedValues: {
      '/responses/0/api_components/0/type': 17,
      '/responses/0/api_components/0/spoiler': true,
      '/responses/0/api_components/0/accent_color': 65280,
      '/responses/0/api_components/0/components/0/content': 'Hello',
    },
  ),
  SandboxFunctionCase(
    'addsection',
    r'$addSection$addTextDisplay[Hello]$addThumbnail[https://example.com/image.png;Picture;false]',
    0,
    '',
    label: 'runtime values',
    scenario: {'options': {}},
    expectedValues: {
      '/responses/0/api_components/0/type': 9,
      '/responses/0/api_components/0/components/0/content': 'Hello',
      '/responses/0/api_components/0/accessory/type': 11,
    },
  ),
  SandboxFunctionCase(
    'addthumbnail',
    r'$addSection$addTextDisplay[Hello]$addThumbnail[https://example.com/image.png;Picture;((opts.spoiler))]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'spoiler': true},
    },
    expectedValues: {
      '/responses/0/api_components/0/accessory/media/url':
          'https://example.com/image.png',
      '/responses/0/api_components/0/accessory/description': 'Picture',
      '/responses/0/api_components/0/accessory/spoiler': true,
    },
  ),
  SandboxFunctionCase(
    'addmediagallery',
    r'$addMediaGallery[gallery]$addMediaGalleryItem[https://example.com/image.png;Picture;true]',
    0,
    '',
    label: 'runtime values',
    scenario: {'options': {}},
    expectedValues: {
      '/responses/0/api_components/0/type': 12,
      '/responses/0/api_components/0/items/0/media/url':
          'https://example.com/image.png',
    },
  ),
  SandboxFunctionCase(
    'addmediagalleryitem',
    r'$addMediaGalleryItem[https://example.com/image.png;Picture;((opts.spoiler))]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'spoiler': true},
    },
    expectedValues: {
      '/responses/0/api_components/0/items/0/description': 'Picture',
      '/responses/0/api_components/0/items/0/spoiler': true,
    },
  ),
  SandboxFunctionCase(
    'addfile',
    r'$addFile[attachment://report.txt;((opts.spoiler))]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'spoiler': true},
    },
    expectedValues: {
      '/responses/0/api_components/0/type': 13,
      '/responses/0/api_components/0/spoiler': true,
      '/responses/0/type': 'respondWithComponentV2',
    },
  ),
  SandboxFunctionCase(
    'newmodal',
    r'$newModal[form;Profile]$addModalTextInput[Name;;name;short;2;20;true;Alice;Write a name]',
    0,
    '',
    label: 'header before fields',
    scenario: {'options': {}},
    expectedValues: {
      '/responses/0/api_modal/title': 'Profile',
      '/responses/0/api_modal/custom_id': 'form',
      '/responses/0/api_modal/components/0/component/custom_id': 'name',
    },
  ),
  SandboxFunctionCase(
    'addtextinput',
    r'$addTextInput[name;short;Name;((opts.min));((opts.max));((opts.required));Alice;Write a name]$newModal[form;Profile]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'min': 2, 'max': 20, 'required': false},
    },
    expectedValues: {
      '/responses/0/api_modal/components/0/component/min_length': 2,
      '/responses/0/api_modal/components/0/component/max_length': 20,
      '/responses/0/api_modal/components/0/component/required': false,
    },
  ),
  SandboxFunctionCase(
    'addmodaltextinput',
    r'$addModalTextInput[Name;;name;paragraph;((opts.min));((opts.max));((opts.required));Alice;Write a name]$newModal[form;Profile]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'min': 2, 'max': 20, 'required': false},
    },
    expectedValues: {
      '/responses/0/api_modal/components/0/label': 'Name',
      '/responses/0/api_modal/components/0/component/style': 2,
      '/responses/0/api_modal/components/0/component/min_length': 2,
      '/responses/0/api_modal/components/0/component/required': false,
    },
  ),
  SandboxFunctionCase(
    'addmodaltextdisplay',
    r'$addModalTextDisplay[((opts.instructions))]$addModalTextInput[Name;;name;short;0;100;true;;]$newModal[form;Profile]',
    0,
    '',
    label: 'standalone resolved text',
    scenario: {
      'options': {'instructions': 'Enter your profile name'},
    },
    expectedValues: {
      '/responses/0/api_modal/components/0/type': 10,
      '/responses/0/api_modal/components/0/content': 'Enter your profile name',
      '/responses/0/api_modal/components/1/label': 'Name',
    },
  ),
  SandboxFunctionCase(
    'addmodalselect',
    r'$addModalSelect[user;People;;people;Choose;1;2;((opts.required));false]$newModal[form;Profile]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'required': false},
    },
    expectedValues: {
      '/responses/0/api_modal/components/0/component/type': 5,
      '/responses/0/api_modal/components/0/component/required': false,
    },
  ),
  SandboxFunctionCase(
    'addmodalfileupload',
    r'$addModalFileUpload[Files;;files;0;2;((opts.required))]$newModal[form;Profile]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'required': false},
    },
    expectedValues: {
      '/responses/0/api_modal/components/0/component/type': 19,
      '/responses/0/api_modal/components/0/component/min_values': 0,
      '/responses/0/api_modal/components/0/component/required': false,
    },
  ),
  SandboxFunctionCase(
    'addmodalradiogroup',
    r'$addmodalradiogroup[Plan;;plan;true]$addRadioGroupOption[plan;Basic;basic;Basic plan;true]$newModal[form;Profile]',
    0,
    '',
    label: 'runtime values',
    scenario: {'options': {}},
    expectedValues: {
      '/responses/0/api_modal/components/0/component/type': 21,
      '/responses/0/api_modal/components/0/component/options/0/value': 'basic',
    },
  ),
  SandboxFunctionCase(
    'addradiogroupoption',
    r'$addmodalradiogroup[Plan;;plan;true]$addRadioGroupOption[plan;Basic;basic;Basic plan;true]$newModal[form;Profile]',
    0,
    '',
    label: 'runtime values',
    scenario: {'options': {}},
    expectedValues: {
      '/responses/0/api_modal/components/0/component/options/0/default': true,
    },
  ),
  SandboxFunctionCase(
    'addmodalcheckboxgroup',
    r'$addmodalcheckboxgroup[Plan;;plan;0;2;false]$addCheckboxGroupOption[plan;Basic;basic;Basic plan;true]$newModal[form;Profile]',
    0,
    '',
    label: 'runtime values',
    scenario: {'options': {}},
    expectedValues: {
      '/responses/0/api_modal/components/0/component/type': 22,
      '/responses/0/api_modal/components/0/component/options/0/value': 'basic',
    },
  ),
  SandboxFunctionCase(
    'addcheckboxgroupoption',
    r'$addmodalcheckboxgroup[Plan;;plan;0;2;false]$addCheckboxGroupOption[plan;Basic;basic;Basic plan;true]$newModal[form;Profile]',
    0,
    '',
    label: 'runtime values',
    scenario: {'options': {}},
    expectedValues: {
      '/responses/0/api_modal/components/0/component/options/0/default': true,
    },
  ),
  SandboxFunctionCase(
    'addmodalcheckbox',
    r'$addModalCheckbox[Terms;;terms;((opts.checked))]$newModal[form;Profile]',
    0,
    '',
    label: 'runtime values',
    scenario: {
      'options': {'checked': true},
    },
    expectedValues: {
      '/responses/0/api_modal/components/0/component/type': 23,
      '/responses/0/api_modal/components/0/component/default': true,
    },
  ),
];
