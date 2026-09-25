.pragma library

function settingOn(value, fallback) {
  var text = String(value === undefined || value === null ? fallback : value)
  return text !== "Off"
}

function barTrackText(title, artist, showTitle, showArtist, playing, showPaused) {
  if (!playing && !showPaused) return ""
  var parts = []
  if (showTitle && title) parts.push(String(title))
  if (showArtist && artist) parts.push(String(artist))
  return parts.join(" — ")
}

function barSlotWidth(fixed, cap, fitted, barSize) {
  var width = fitted
  if (cap > 0) width = Math.min(width, cap)
  if (fixed && cap > 0) width = cap
  return Math.max(barSize || 0, Math.ceil(width))
}

function clampUnit(value) {
  return Math.max(0, Math.min(1, Number(value) || 0))
}

function parseStatus(text) {
  try {
    var data = JSON.parse(String(text || "{}"))
    if (data && typeof data === "object") return data
  } catch (error) {
    return null
  }
  return null
}

function helperPath(url) {
  return decodeURIComponent(String(url || "").replace(/^file:\/\//, ""))
}

function millisecondsToClock(milliseconds) {
  var seconds = Math.max(0, Math.floor((Number(milliseconds) || 0) / 1000))
  var minutes = Math.floor(seconds / 60)
  var remainder = seconds % 60
  return minutes + ":" + (remainder < 10 ? "0" : "") + remainder
}

function parsePinnedStations(raw) {
  if (raw instanceof Array) return raw
  var text = String(raw || "").trim()
  if (!text) return []
  try {
    var parsed = JSON.parse(text)
    return parsed instanceof Array ? parsed : []
  } catch (error) {
    return []
  }
}

function stationPath(item) {
  if (!item) return ""
  if (typeof item === "string") return item
  return String(item.path || "")
}

function playbackSliderFeedbackComplete(sourceValue, pendingValue, sourcePending,
    elapsed, tolerance, minimumMs, timeoutMs) {
  if (elapsed >= timeoutMs) return true
  if (elapsed < minimumMs) return false
  if (sourcePending) return false
  return Math.abs((Number(sourceValue) || 0) - (Number(pendingValue) || 0)) <= tolerance
}
