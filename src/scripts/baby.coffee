handleData = (data, tabletop) ->
  console.log("Data loaded!")
  $(".loader").hide()
  $(".main-content").show()
  window.data = data
  window.tabletop = tabletop

  keys = deserializeKeyRows(data)

  flags = _.object([k.name, k.value] for k in keys when k.type == "flag")
  document.title = flags["title"] ? "Trackinator"
  $("h1").text(flags["title"] ? "Trackinator")

  eventKeys = (k for k in keys when k.type == "event")
  stateKeys = (k for k in keys when k.type == "state")
  eventTrendKeys = (k for k in keys when k.type == "event-trend")
  stateTrendKeys = (k for k in keys when k.type == "state-trend")
  alignKeys = (k for k in keys when k.type == "align")

  rows = deserializeEventRows(data)
  events = rowsToEvents(rows, eventKeys)
  stateEvents = generateStateEvents(events, stateKeys)
  allEvents = _.sortBy(events.concat(stateEvents), (ev) -> ev.start)

  curTimelines = [[]]

  if alignKeys.length == 0
    $(".alignment-controls").hide()
  else
    $alignControls = $(".alignment-controls .controls-options").empty()
    $("<label><input type='radio' name='align' value='date' checked/>Date</label>").appendTo($alignControls)
    for key in alignKeys
      $("<label/>").text(key.name).prepend($("<input type='radio' name='align'/>").prop("value", key.name)).appendTo($alignControls)
  
  $(".alignment-controls input").click ->
    curTimelines[0] = renderTimelines(allEvents, $(@).prop("value"), alignKeys, eventTrendKeys, stateTrendKeys)

  $(".expansion-controls input").click ->
    timelines = curTimelines[0]
    if $(@).is(":checked")
      for timeline in timelines[0...timelines.length-1]
        timeline.setGroups([{id: "point", content: "Events"}])
        timeline.setOptions({height: "200px", stack: true})
    else
      for timeline in timelines[0...timelines.length-1]
        timeline.setGroups([{id: "state", content: "State"}])
        timeline.setOptions({height: null, stack: false})

  curTimelines[0] = renderTimelines(allEvents, "date", alignKeys, eventTrendKeys, stateTrendKeys)

renderGroupHeader = (group, stateTrendKeys, eventTrendKeys) ->
  $container = $("<div/>")
  $container.append($("<h2/>").text(group.title))
  $aggs = $("<ul/>").addClass("aggs").appendTo($container)
  stateStats = _.object([k.name, 0] for k in stateTrendKeys)
  eventStats = _.object([k.name, 0] for k in eventTrendKeys)
  for event in group.events
    if event.stateKey?
      for key in stateTrendKeys
        if containsAction(event.stateKey.name, key.value)
          stateStats[key.name] += intervalOverlap(event.start, event.end, group.minDate, group.maxDate)
    else
      for key in eventTrendKeys
        if containsActions([event.eventKey?.name, event.text], key.value)
          eventStats[key.name] += 1
  for key in stateTrendKeys
    $("<li/>").append($("<span class='agg-key'/>").text("#{key.name}").css("backgroundColor", key.backgroundcolor ? "").css("color", key.foregroundcolor ? "")).append($("<span class='agg-val'/>").text("#{moment.duration(stateStats[key.name]).humanize()}")).appendTo($aggs)
  for key in eventTrendKeys
    $("<li/>").append($("<span class='agg-key'/>").text("#{key.name}").css("backgroundColor", key.backgroundcolor ? "").css("color", key.foregroundcolor ? "")).append($("<span class='agg-val'/>").text("#{eventStats[key.name]}x")).appendTo($aggs)
  return $container

renderTimelines = (allEvents, mode, alignKeys, eventTrendKeys, stateTrendKeys) ->
  boundaryCond = if mode == "date" then dateBoundaryCond else customBoundaryCond((_.find alignKeys, (k) -> k.name == mode).value)
  groupedEvents = groupEventsByBoundary(allEvents, boundaryCond)
  setGroupDateRanges(mode, groupedEvents)

  $body = $(".timelines-container").empty()
  $table = $("<table/>").addClass("timelines-table").appendTo($body)

  $tr = $("<tr/>").appendTo($table)
  $("<td/>").addClass("header").appendTo($tr).append($("<h2/>").text("Trends"))
  $summariesTimeline = $("<td/>").appendTo($tr)

  timelines = []
  for group in groupedEvents.reverse()
    $tr = $("<tr/>").appendTo($table)
    $("<td/>").addClass("header").appendTo($tr).append(renderGroupHeader(group, stateTrendKeys, eventTrendKeys))
    $timeline = $("<td/>").appendTo($tr)
    timeline = renderEvents($timeline, group)
    timelines.push(timeline)

  summariesTimeline = generateSummaries($summariesTimeline, timelines, eventTrendKeys, stateTrendKeys)
  timelines.push(summariesTimeline)
  window.st = summariesTimeline

  window.timelines = timelines

  handlingEvent = false
  for timeline in timelines
    timeline.on "rangechanged", (event) ->
      if handlingEvent
        return
      handlingEvent = true
      setRange(timelines, event.start, event.end)
      handlingEvent = false
  setRange(timelines, timelines[0].getWindow().start, timelines[0].getWindow().end)

  return timelines

setGroupDateRanges = (mode, groups) ->
  for g in groups
    range = getEventsDateRange(g.events)
    g.firstDate = range.min
    g.lastDate = range.max

  if mode == "date"
    for group, i in groups
      group.minDate = moment(group.firstDate).startOf("day").toDate()
      group.maxDate = moment(group.lastDate).endOf("day").toDate()
  else
    maxDuration = _.max(g.lastDate - g.firstDate for g in groups)
    for group in groups
      group.minDate = moment(group.firstDate).toDate()
      group.maxDate = moment(group.firstDate).add(maxDuration, "milliseconds").toDate()

setRange = (timelines, start, end) ->
  anchor = _.find timelines, (t) -> t.getWindow().start.valueOf() == start.valueOf() and t.getWindow().end.valueOf() == end.valueOf()
  startDiff = start - anchor.dateRange.min
  rangeDiff = end - start
  for timeline in timelines
    if timeline == anchor
      continue
    else
      tstart = moment(timeline.dateRange.min).add(startDiff, "ms")
      tend = moment(tstart + rangeDiff)
      timeline.setWindow(tstart.toDate(), tend.toDate(), {animate: false})

FEED_ACTIONS = ["feed", "nurse"]

containsAction = (action, checks) ->
  _.any(action.toLowerCase().indexOf(s) >= 0 for s in checks)

dateBoundaryCond = (cur, event) ->
  day = moment(event.start).format("MMMM Do")
  if cur != day then day else undefined

customBoundaryCond = (values) ->
  (cur, event) ->
    if containsAction(event.text, values)
      return moment(event.start).format("MMMM Do, h:ma")
    else
      return undefined

groupEventsByBoundary = (events, boundaryCondition) ->
  results = []
  curBoundary = undefined
  curEvents = []
  curState = undefined
  for event in events
    boundary = boundaryCondition(curBoundary, event)
    if boundary?
      if curEvents.length > 0
        results.push {title: curBoundary, events: curEvents}
        curEvents = []
        if curState?
          curEvents.push curState
      curBoundary = boundary

    if not curBoundary?
      continue

    curEvents.push event

    if event.end?
      curState = event

  if curEvents.length > 0
    results.push {title: curBoundary, events: curEvents}

  results

rowsToEvents = (rows, eventKeys) ->
  _.map rows, (row) ->
    eventKey = _.find eventKeys, (k) -> containsAction(row.action, k.value)
    {
      content: $("<span/>").append($("<span class='event-content'/>").append($("<span class='event-time event-start'/>").text(row.timestamp.format("h:mma"))).append($("<span class='event-action'/>").text(row.action))).html()
      text: row.action
      start: row.timestamp.toDate()
      group: "point"
      type: "box"
      title: row.action
      eventKey: eventKey
      style: "background-color: #{eventKey?.backgroundcolor ? ''}; border-color: #{eventKey?.backgroundcolor ? ''}; color: #{eventKey?.foregroundcolor ? ''};"
    }

containsActions = (actions, values) ->
  for action in actions
    if action? and containsAction(action, values)
      return true
  return false

generateStateEvents = (events, stateKeys) ->
  results = []
  curState = undefined

  stateContentHtml = (state) ->
    $("<div/>").append($("<div class='event-content'/>").append($("<div class='event-time event-start'/>").text(moment(state.start).format("h:mma"))).append($("<div class='event-action'/>").text(state.text)).append($("<div class='event-time event-end'/>").text(moment(state.end).format("h:mma")))).html()

  for event in events
    stateKey = _.find stateKeys, (k) -> containsActions([event.text, event.eventKey?.name], k.value)
    if stateKey?        
      if curState? and curState.text != stateKey.name
        curState.end = event.start
        curState.content = stateContentHtml(curState)
        results.push curState
      if not curState? or curState?.text != stateKey.name
        curState = {
          content: ""
          text: stateKey.name,
          start: event.start,
          group: "state",
          type: "range",
          title: stateKey.name,
          stateKey: stateKey,
          #className: "state state-#{type}"
          style: "background-color: #{stateKey.backgroundcolor ? ''}; border-color: #{stateKey.backgroundcolor ? ''}; color: #{stateKey.foregroundcolor ? ''};"
        }

  if curState?
    curState.end = moment(curState.start).add(1, "hour").toDate()
    curState.content = stateContentHtml(curState)
    results.push curState

  results

getEventsDateRange = (events) ->
  pointEvents = (ev for ev in events when not ev.end?)
  maxEvent = _.max pointEvents, (ev) -> ev.start
  minEvent = _.min pointEvents, (ev) -> ev.start
  {min: minEvent.start, max: maxEvent.start}

renderSummaries = ($container, title, events) ->
  $("<h2/>").text(title).appendTo($container);
  $timeline = $("<div/>").appendTo($container);
  items = new vis.DataSet()

generateSummaries = ($container, timelines, eventTrendKeys, stateTrendKeys) ->
  PERIOD = 30

  duration = _.max(t.dateRange.max - t.dateRange.min for t in timelines)

  intervals = []
  for i in [0...Math.ceil(duration / (PERIOD * 60 * 1000))]
    iv = {
      index: i
    }
    for key in eventTrendKeys
      iv[key.name] = 0
    for key in stateTrendKeys
      iv[key.name] = 0
    intervals.push(iv)

  aggregateInterval = (timeline, interval, start, end) ->
    for event in timeline.itemsData.get()
      if stateTrendKeys.length > 0 and event.stateKey? and event.group == "state"
        overlap = intervalOverlap(event.start, event.end, start, end)
        if overlap > 0
          for key in stateTrendKeys
            if containsAction(event.stateKey.name, key.value)
              interval[key.name] += overlap / 1000 / 60
      else if eventTrendKeys.length > 0 and event.group == "point" and timeIn(event.start, start, end)
        for key in eventTrendKeys
          if containsActions([event.eventKey?.name, event.text], key.value)
            interval[key.name] += 1
  
  for iv, i in intervals
    for timeline in timelines
      start = moment(timeline.dateRange.min).add(i * PERIOD, "minutes").toDate()
      end = moment(start).add(PERIOD, "minutes").toDate()
      aggregateInterval(timeline, iv, start, end)

  now = moment()
  startTime = moment(now).startOf("day")
  events = []

  maxStateKeys = (_.max(iv[k.name] for iv in intervals) for k in stateTrendKeys)
  minStateKeys = (_.min(iv[k.name] for iv in intervals) for k in stateTrendKeys)
  maxEventKeys = (_.max(iv[k.name] for iv in intervals) for k in eventTrendKeys)
  minEventKeys = (_.min(iv[k.name] for iv in intervals) for k in eventTrendKeys)

  for iv, i in intervals
    endTime = moment(startTime).add(PERIOD, "minutes")
    for key, j in stateTrendKeys
      events.push {
        content: "#{iv[key.name]}"
        text: "#{iv[key.name]}"
        title: "#{iv[key.name]}"
        start: startTime.toDate()
        end: endTime.toDate()
        group: key.name
        type: "background"
        className: "summary"
        style: "background-color: #{key.backgroundcolor ? ''}; border-color: #{key.backgroundcolor ? ''}; color: #{key.foregroundcolor ? ''}; opacity: #{(iv[key.name]-minStateKeys[j])/(maxStateKeys[j]-minStateKeys[j])}"
      }
    for key, j in eventTrendKeys
      events.push {
        content: "#{iv[key.name]}"
        text: "#{iv[key.name]}"
        title: "#{iv[key.name]}"
        start: startTime.toDate()
        end: endTime.toDate()
        group: key.name
        type: "background"
        className: "summary"
        style: "background-color: #{key.backgroundcolor ? ''}; border-color: #{key.backgroundcolor ? ''}; color: #{key.foregroundcolor ? ''}; opacity: #{(iv[key.name]-minEventKeys[j])/(maxEventKeys[j]-minEventKeys[j])}"
      }
    startTime = endTime

  dateRange = {
    min: moment(now).startOf("day").toDate()
    max: moment(now).startOf("day").add(PERIOD * intervals.length, "minutes").toDate()
  }

  options = {
    showMajorLabels: false
    min: moment(dateRange.min).subtract(1, "hour").toDate()
    max: moment(dateRange.max).add(1, "hour").toDate()
  }

  groups = ({id: k.name, content: k.name} for k in stateTrendKeys.concat eventTrendKeys)
  timeline = new vis.Timeline($container[0], events, groups, options)
  timeline.dateRange = dateRange
  return timeline

intervalOverlap = (start1, end1, start2, end2) ->
  if start1 <= start2 and end1 >= end2
    end2 - start2
  else if start1 >= start2 and end1 <= end2
    end1 - start1
  else if start1 <= start2 and end1 >= start2
    end1 - start2
  else if start1 >= start2 and start1 <= end2
    end2 - start1
  else
    0

timeIn = (date, start, end) ->
  return date >= start and date <= end    


renderEvents = ($container, group) ->
  items = new vis.DataSet()
  options = {
    height: "200px"
    padding: 2
    showMajorLabels: false
    max: moment(group.maxDate).add(1, "hour").toDate()
    min: moment(group.minDate).subtract(1, "hour").toDate()
  }
  for event in group.events
    items.add(event)
    if event.end?
      bgEvent = _.clone(_.omit(event, ["id"]))
      _.extend bgEvent, {
        group: "point", content: "", style: bgEvent.style + "; opacity: 0.2", type: "background"
      }
      items.add(bgEvent)

  timeline = new vis.Timeline($container[0], items, [{id: "point", content: "Events"}], options)
  timeline.dateRange = {max: group.maxDate, min: group.minDate}
  return timeline

deserializeKeyRows = (data) ->
  keys = data["Keys"]?.all() ? []
  for key in keys
    key.value = (s.trim() for s in key.value.split(","))
  return keys

deserializeEventRows = (data) ->
  allRows = []
  for sheetName, sheet of data
    rows = sheet.elements;
    if _.all(_.contains(sheet.column_names, name) for name in ["timestamp", "time", "action", "date", "minutesago"])
      for row in rows
        submitTimestamp = if row.timestamp then moment(row.timestamp, "M/DD/YYYY H:mm:ss") else undefined
        if row.minutesago
          row.timestamp = submitTimestamp.subtract(parseInt(row.minutesago), "minutes")
        else if not row.time
          row.timestamp = submitTimestamp
        else if not row.date
          row.timestamp = moment("#{submitTimestamp.format('M/DD/YYYY')} #{row.time}", "M/DD/YYYY H:mm:ss A")
        else
          row.timestamp = moment("#{row.date} #{row.time}", "M/DD/YYYY H:mm:ss A")
        allRows.push row
    else
      console.log("Skipping sheet #{sheetName}")

  return _.sortBy(allRows, (r) -> r.timestamp.valueOf())

$ ->
  hash = window.location.hash.substring(1)
  if hash
    key = hash
  else
    key = SPREADSHEET_KEY

  if not key
    key = prompt("What is the key for the spreadsheet?")
    window.location.hash = "##{key}"
    window.location.reload()
    return

  console.log("Loading data...")
  Tabletop.init {
    key: key
    callback: handleData
  }
