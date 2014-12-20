zoe-tracker
===========

Instructions
------------
1. Create a tracking Google Sheet [using the template here here](https://drive.google.com/previewtemplate?id=14JHPhi8x2Sna8vBT4zYnEC-EATy7tDW8lKSORkMw5zU&mode=public).  Just click "Use this template".
2. You'll probably want to rename the spreadsheet and the associated form.
3. Publish the sheet to the web; go to `File | Publish to the web...`, and publish the entire spreadsheet.
4. Go to the [tracker visualization website](https://chungwu.github.io/zoe-tracker/), and enter your spreadsheet key.  The spreadsheet key can be found in the URL of your spreadsheet; it looks like `https://docs.google.com/spreadsheets/d/{LONG_KEY_STRING_HERE}/edit`

Tracking events
---------------
The spreadsheet comes with a form; use the live form to submit actions that you're tracking, as they happen.  You can access the form by clicking `Form | Go to live form`.

The "Action" should just be whatever short string you want to describe what happened.  You can decide what these strings are.  "Action" is the only required field; all other fields will just be used to figure out when the action actually happened.  If it happened _just now_, you can leave the rest of the form blank.  If it happened a few minutes ago, fill out how many minutes ago.  If it happened at a specific time, enter the specific time.  If it happened on another date, enter the specific time and date.

Once you've submitted a form, there is a useful link to "Submit another response".

The form responses are gathered in the "Form Responses 1" tab.  You can manually enter entries here too with arbitrary timestamps.  

Defining events / states / colors / etc.
----------------------------------------
You can define your own events and states, with custom colors, by editing the "Keys" tab of the spreadsheet.  More documentation to come, but for now, you can mime what exists in the example template.
