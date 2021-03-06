local wibox = require('wibox')
local awful = require('awful')
local iconic = require('iconic')
local utility = require('utility')
local theme = require('beautiful')

-- Module topjets.unitybar
local unitybar = { tag_widgets = {} }

local function constrain(wdg, size)
   return wibox.layout.constraint(wdg, 'exact', size, size)
end

function update_tag(tag, wdg)
   wdg:reset()

   local bgb = wibox.widget.background()
   bgb:set_bgimage(tag.selected and unitybar.args.img_focused)
   wdg:set_widget(bgb)

   local middle = wibox.layout.align.horizontal()
   bgb:set_widget(middle)

   local visible_clients, pivot, urgent = {}, 0, false
   for _, c in ipairs(tag:clients()) do
      if not (c.skip_taskbar or c.hidden
              or c.type == "splash" or c.type == "dock" or c.type == "desktop")
      then
         local im = wibox.widget.imagebox()
         im:set_image(c.icon or unitybar.args.default_icon)
         im.client = c
         im:buttons(utility.keymap("LMB", function()
                                      awful.tag.viewonly(tag)
                                      c:raise()
                                      client.focus = c
         end))
         table.insert(visible_clients, im)
         if client.focus == c then
            pivot = #visible_clients
         end
         if c.urgent then
            urgent = true
         end
      end
   end

   if urgent then
      bgb:set_bg(unitybar.args.bg_urgent)
   end

   if #visible_clients == 0 then
      local alignedv = wibox.layout.align.vertical()
      local aligned = wibox.layout.align.horizontal()
      middle:set_middle(alignedv)
      alignedv:set_middle(aligned)
      local num = wibox.widget.textbox(string.format('<span color="%s">%s</span>',
                                                     unitybar.args.fg_normal, tag.name))
      middle:buttons(utility.keymap(
                        "LMB", function() awful.tag.viewonly(tag) end))
      aligned:set_middle(num)
      return
   end

   if pivot ~= 0 then
      local content = wibox.layout.fixed.horizontal()
      middle:set_middle(content)
      local alignedf = wibox.layout.align.vertical()
      local front = constrain(visible_clients[pivot], 35)
      alignedf:set_middle(front)
      local aligned = wibox.layout.align.vertical()
      local back = wibox.layout.fixed.vertical()
      content:add(alignedf)
      aligned:set_middle(back)
      content:add(aligned)

      local max = 3

      for i = pivot - 1, 1, -1 do
         if max ~=0 then
            back:add(constrain(visible_clients[i], 17))
            max = max - 1
         end
      end
      for i = #visible_clients, pivot + 1, -1 do
         if max ~=0 then
            back:add(constrain(visible_clients[i], 19))
            max = max - 1
         end
      end
   else
      local alignedv = wibox.layout.align.vertical()
      local aligned = wibox.layout.align.horizontal()
      middle:set_middle(alignedv)
      local rowstack = wibox.layout.fixed.vertical()
      local first_row = wibox.layout.fixed.horizontal()
      alignedv:set_middle(aligned)
      aligned:set_middle(rowstack)
      rowstack:add(first_row)
      if #visible_clients <= 3 then
         for i = 1, #visible_clients do
            first_row:add(constrain(visible_clients[i], 19))
         end
      else
         local second_row = wibox.layout.fixed.horizontal()
         rowstack:add(second_row)
         local num_cli = ((#visible_clients > 6) and 6 or #visible_clients)
         for i = 1, math.ceil(num_cli / 2) do
            first_row:add(constrain(visible_clients[i], 19))
         end
         for i = math.ceil(num_cli / 2) + 1, num_cli do
            second_row:add(constrain(visible_clients[i], 19))
         end
      end
   end
end

local tag_signals = { "property::activated", "property::selected",
                      "property::hide", "property::name",
                      "property::screen", "property::index" }

local client_signals = {"property::urgent", "property::sticky",
                        "property::ontop", "property::floating",
                        "property::maximized_horizontal",
                        "property::maximized_vertical",
                        "property::minimized", "property::name",
                        "property::icon_name", "property::icon",
                        "property::skip_taskbar", "property::screen",
                        "property::hidden", "tagged", "untagged",
                        "unmanage", "list", "focus", "unfocus" }

function unitybar.new(args)
   local args = args or {}
   args.width = args.width or 60
   args.default_icon = args.default_icon or iconic.lookup_icon("application-default-icon")
   args.fg_normal = args.fg_normal or theme.fg_normal or "#ffffff"
   args.bg_urgent = args.bg_urgent or theme.bg_urgent or "#ff0000"
   unitybar.args = args

   local s = args.screen or 1
   local tags = awful.tag.gettags(s)

   unitybar.tag_widgets[s] = {}

   local bar = wibox.layout.fixed.vertical()
   for _, tag in ipairs(tags) do
      local tag_widget = constrain(nil, args.width)
      local u = function() update_tag(tag, tag_widget) end
      for _, signal in ipairs(tag_signals) do
         awful.tag.attached_connect_signal(s, signal, u)
      end
      for _, signal in ipairs(client_signals) do
         client.connect_signal(signal, u)
      end
      u()
      table.insert(unitybar.tag_widgets[s], tag_widget)
      bar:add(constrain(tag_widget, args.width))
   end
   return bar
end

return setmetatable(unitybar, { __call = function(_, ...) return unitybar.new(...) end})
