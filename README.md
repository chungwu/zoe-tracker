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

Brief description of available options below.  Cells that `look like this` are predefined strings that must be entered as-is; other cells can be customized to your liking.

Type | Name | Value | Background / Foreground Colors | Description
--- | --- | --- | --- | --- | ---
`flag` | `title` | Title of your visualization | _ignored_ | This configures the header and page title of the visualization
`event` | Event name | Comma-separated list of action substrings | Colors used for the event markers | Define a class of events whose markers should be colored a certain way. In the Value column, you can specify a comma-separated list of substrings to look for in a Actions that should be marked as this event type.
`state` | State name | Comma-separated list of event or action substrings | Colors used for the state regions | Defines a state of being that is usually defined by a starting and ending event.  The Value column specifies a comma-separated list of substrings for event names or actions that should trigger transition into this state.  For example, the "sleeps" event will trigger transition into the "asleep" state, etc.
`state-trend` | Name of state trend | Comma-separated list of state names | Colors used for trend heatmap | Defines a trend heatmap at the top of the visualization that expresses how often you are in this state at each block of time.
`event-trend` | Name of event trend | Comma-separated list of event names | Colors used for trend heatmap | Defines a trend heatmap at the top of the visualizationt hat expresses how often this event occurs.
`align` | Name of alignment | Comma-separated list of event substrings | _ignored_ | Defines a way to "align" the timelines.  By default, the timelines are aligned by the start of each date.  But you can add an option here to instead align the timelines by the start of this event, expressed in the Value column.  For example, you might have an event called "morning wake", and have an alignment by that, so you would align the timelines by when a baby wakes up, rather than by midnight of each date.  This allows you to see trend by offset relative to some milestone event, rather than by time.
