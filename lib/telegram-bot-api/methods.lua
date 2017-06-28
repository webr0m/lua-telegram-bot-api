local json = require 'cjson'
local http = require 'resty.http'

local _M = {}

_M.VERSION = '3.0.0.0'

function _M.init(bot_api_key, reply)
	_M.BASE_URL = 'https://api.telegram.org/bot'..bot_api_key..'/'
	_M.REPLY = reply
	return _M
end

local function request(method, body)
	if _M.REPLY then -- Return request table to be used to reply the webhook
		local res = {}
		if body then res = body end
		res.method = method
		return res
	else -- Return the result of an HTTP request
		local arguments = {}
		if body then
			body = json.encode(body)
			arguments =
			{
				method = 'POST',
				headers = {['Content-Type'] = 'application/json'},
				body = body
			}
			ngx.log(ngx.DEBUG, 'Outgoing request: '..body)
		end
		local httpc = http.new()
		local res, err = httpc:request_uri((_M.BASE_URL..method), arguments)
		if res then
			ngx.log(ngx.DEBUG, 'Incoming reply: '..res.body)
			local tab = json.decode(res.body)
			if res.status == 200 and tab.ok then
				return tab
			else
				ngx.log(ngx.INFO, 'Failed: '..tab.description)
				return false, tab
			end
		else
			ngx.log(ngx.ERR, err) -- HTTP request failed
		end
	end
end

-- Pre-processors
local function pre_msg(body, disable_notification, reply_to_message_id, reply_markup)
	if disable_notification then body.disable_notification = disable_notification end
	if reply_to_message_id then body.reply_to_message_id = reply_to_message_id end
	if reply_markup then body.reply_markup = reply_markup end
	return body
end

local function pre_text(body, text, parse_mode, disable_web_page_preview)
	body.text = text
	if parse_mode then body.parse_mode = parse_mode end
	if disable_web_page_preview then body.disable_web_page_preview = disable_web_page_preview end
	return body
end

local function pre_media(body, caption, duration)
	if caption then body.caption = caption end
	if duration then body.duration = duration end
	return body
end

local function pre_edit(body, chat_id, message_id, inline_message_id)
	if inline_message_id then
		body.inline_message_id = inline_message_id
	else
		body.chat_id = chat_id
		body.message_id = message_id
	end
	return body
end

-- Getting updates

function _M.getUpdates(offset, limit, timeout, allowed_updates)
	local body = {}
	if offset then body.offset = offset end
	if limit then body.limit = limit end
	if timeout then body.timeout = timeout end
	if allowed_updates then body.allowed_updates = allowed_updates end
	return request('getUpdates', body)
end

function _M.setWebhook(url, certificate, max_connections, allowed_updates)
	local body = {url = url}
	if certificate then body.certificate = certificate end
	if max_connections then body.max_connections = max_connections end
	if allowed_updates then body.allowed_updates = allowed_updates end
	request('setWebhook', body)
end

function _M.deleteWebhook()
	return request('deleteWebhook')
end

function _M.getWebhookInfo()
	return request('getWebhookInfo')
end

-- Available methods

function _M.getMe()
	return request('getMe')
end

function _M.sendMessage(chat_id, text, parse_mode, disable_web_page_preview, disable_notification, reply_to_message_id,
	reply_markup)
	local body = {chat_id = chat_id}
	body = pre_text(body, text, parse_mode, disable_web_page_preview)
	body = pre_msg(body, disable_notification, reply_to_message_id, reply_markup)
	return request('sendMessage', body)
end

function _M.forwardMessage(chat_id, from_chat_id, disable_notification, message_id)
	local body =
	{
		chat_id = chat_id,
		from_chat_id = from_chat_id,
		message_id = message_id
	}
	body = pre_msg(body, disable_notification)
	return request('forwardMessage', body)
end

function _M.sendPhoto(chat_id, photo, caption, disable_notification, reply_to_message_id, reply_markup)
	local body =
	{
		chat_id = chat_id,
		photo = photo
	}
	body = pre_media(body, caption)
	body = pre_msg(body, disable_notification, reply_to_message_id, reply_markup)
	return request('sendPhoto', body)
end

function _M.sendAudio(chat_id, audio, caption, duration, performer, title, disable_notification, reply_to_message_id,
	reply_markup)
	local body =
	{
		chat_id = chat_id,
		audio = audio
	}
	if performer then body.performer = performer end
	if title then body.title = title end
	body = pre_media(body, caption, duration)
	body = pre_msg(body, disable_notification, reply_to_message_id, reply_markup)
	return request('sendAudio', body)
end

function _M.sendDocument(chat_id, document, caption, disable_notification, reply_to_message_id, reply_markup)
	local body =
	{
		chat_id = chat_id,
		document = document
	}
	body = pre_media(body, caption)
	body = pre_msg(body, disable_notification, reply_to_message_id, reply_markup)
	return request('sendDocument', body)
end

function _M.sendSticker(chat_id, sticker, caption, disable_notification, reply_to_message_id, reply_markup)
	local body =
	{
		chat_id = chat_id,
		sticker = sticker
	}
	body = pre_media(body, caption)
	body = pre_msg(body, disable_notification, reply_to_message_id, reply_markup)
	return request('sendSticker', body)
end

function _M.sendVideo(chat_id, video, duration, width, height, caption, disable_notification, reply_to_message_id,
	reply_markup)
	local body =
	{
		chat_id = chat_id,
		video = video
	}
	if width then body.width = width end
	if height then body.height = height end
	body = pre_media(body, caption, duration)
	body = pre_msg(body, disable_notification, reply_to_message_id, reply_markup)
	return request('sendVideo', body)
end

function _M.sendVoice(chat_id, voice, caption, duration, disable_notification, reply_to_message_id, reply_markup)
	local body =
	{
		chat_id = chat_id,
		voice = voice
	}
	body = pre_media(body, caption, duration)
	body = pre_msg(body, disable_notification, reply_to_message_id, reply_markup)
	return request('sendVoice', body)
end

function _M.sendVideoNote(chat_id, video_note, duration, lenght, disable_notification, reply_to_message_id,
	reply_markup)
	local body =
	{
		chat_id = chat_id,
		video_note = video_note
	}
	if lenght then body.lenght = lenght end
	body = pre_media(body, false, duration)
	body = pre_msg(body, disable_notification, reply_to_message_id, reply_markup)
	return request('sendVideoNote', body)
end

function _M.sendLocation(chat_id, latitude, longitude, reply_to_message_id, reply_markup)
	local body =
	{
		chat_id = chat_id,
		latitude = latitude,
		longitude = longitude
	}
	if latitude then body.latitude = latitude end
	if longitude then body.longitude = longitude end
	body = pre_msg(body, false, reply_to_message_id, reply_markup)
	return request('sendLocation', body)
end

function _M.sendVenue(chat_id, latitude, longitude, title, address, foursquare_id, disable_notification,
	reply_to_message_id, reply_markup)
	local body =
	{
		chat_id = chat_id,
		latitude = latitude,
		longitude = longitude
	}
	if title then body.title = title end
	if address then body.address = address end
	if foursquare_id then body.foursquare_id = foursquare_id end
	body = pre_msg(body, disable_notification, reply_to_message_id, reply_markup)
	return request('sendVenue', body)
end

function _M.sendContact(chat_id, phone_number, first_name, last_name, disable_notification, reply_to_message_id,
	reply_markup)
	local body =
	{
		chat_id = chat_id,
		phone_number = phone_number,
		first_name = first_name
	}
	if last_name then body.last_name = last_name end
	body = pre_msg(body, disable_notification, reply_to_message_id, reply_markup)
	return request('sendContact', body)
end

function _M.sendChatAction(chat_id, action)
	local body =
	{
		chat_id = chat_id,
		action = action
	}
	return request('sendChatAction', body)
end

function _M.getUserProfilePhotos(user_id, offset, limit)
	local body = {user_id = user_id}
	if offset then body.offset = offset end
	if limit then body.limit = limit end
	return request('getUserProfilePhotos', body)
end

function _M.getFile(file_id)
	local body = {file_id = file_id}
	return request('getFile', body)
end

function _M.kickChatMember(chat_id, user_id)
	local body =
	{
		chat_id = chat_id,
		user_id = user_id
	}
	return request('kickChatMember', body)
end

function _M.unbanChatMember(chat_id, user_id)
	local body =
	{
		chat_id = chat_id,
		user_id = user_id
	}
	return request('unbanChatMember', body)
end

function _M.leaveChat(chat_id)
	local body = {chat_id = chat_id}
	return request('leaveChat', body)
end

function _M.getChat(chat_id)
	local body = {chat_id = chat_id}
	return request('getChat', body)
end

function _M.getChatAdministrators(chat_id)
	local body = {chat_id = chat_id}
	return request('getChatAdministrators', body)
end

function _M.getChatMembersCount(chat_id)
	local body = {chat_id = chat_id}
	return request('getChatMembersCount', body)
end

function _M.getChatMember(chat_id, user_id)
	local body =
	{
		chat_id = chat_id,
		user_id = user_id
	}
	return request('getChatMember', body)
end

function _M.answerCallbackQuery(callback_query_id, text, show_alert, cache_time)
	local body = {callback_query_id = callback_query_id}
	if text then body.text = text end
	if show_alert then body.show_alert = show_alert end
	if cache_time then body.cache_time = cache_time end
	return request('answerCallbackQuery', body)
end

-- Updating messages

function _M.editMessageText(chat_id, message_id, inline_message_id, text, parse_mode, disable_web_page_preview,
	reply_markup)
	local body = {}
	body = pre_edit(body, chat_id, message_id, inline_message_id)
	body = pre_text(body, text, parse_mode, disable_web_page_preview)
	body = pre_msg(body, false, false, reply_markup)
	return request('editMessageText', body)
end

function _M.editMessageCaption(chat_id, message_id, inline_message_id, caption, reply_markup)
	local body = {}
	if caption then body.caption = caption end
	body = pre_edit(body, chat_id, message_id, inline_message_id)
	body = pre_msg(body, false, false, reply_markup)
	return request('editMessageCaption', body)
end

function _M.editMessageReplyMarkup(chat_id, message_id, inline_message_id, reply_markup)
	local body = {}
	body = pre_edit(body, chat_id, message_id, inline_message_id)
	body = pre_msg(body, false, false, reply_markup)
	return request('editMessageReplyMarkup', body)
end

function _M.deleteMessage(chat_id, message_id)
	local body =
	{
		chat_id = chat_id,
		message_id = message_id
	}
	return request('deleteMessage', body)
end

-- Inline mode

function _M.answerInlineQuery(inline_query_id, results, cache_time, is_personal, switch_pm_text, switch_pm_parameter)
	local body =
	{
		inline_query_id = inline_query_id,
		results = results
	}
	if cache_time then body.cache_time = cache_time end
	if is_personal then body.is_personal = is_personal end
	if switch_pm_text then body.switch_pm_text = switch_pm_text end
	if switch_pm_parameter then body.switch_pm_parameter = switch_pm_parameter end
	return request('answerInlineQuery', body)
end

-- Payments

function _M.sendInvoice(chat_id, title, description, payload, provider_token, start_parameter, currency, prices,
	photo_url, photo_width, photo_height, need_name, need_phone_number, need_email, need_shipping_address, is_flexible,
	disable_notification, reply_to_message_id, reply_markup)
	local body =
	{
		chat_id = chat_id,
		title = title,
		description = description,
		payload = payload,
		provider_token = provider_token,
		start_parameter = start_parameter,
		currency = currency,
		prices = prices
	}
	if photo_url then body.photo_url = photo_url end
	if photo_width then body.photo_width = photo_width end
	if photo_height then body.photo_height = photo_height end
	if need_name then body.need_name = need_name end
	if need_phone_number then body.need_phone_number = need_phone_number end
	if need_email then body.need_email = need_email end
	if need_shipping_address then body.need_shipping_address = need_shipping_address end
	if is_flexible then body.is_flexible = is_flexible end
	body = pre_msg(body, disable_notification, reply_to_message_id, reply_markup)
	return request('sendInvoice', body)
end

function _M.answerShippingQuery(shipping_query_id, ok, shipping_options, error_message)
	local body =
	{
		shipping_query_id = shipping_query_id,
		ok = ok
	}
	if shipping_options then body.shipping_options = shipping_options end
	if error_message then body.error_message = error_message end
	return request('answerShippingQuery', body)
end

function _M.answerPreCheckoutQuery(pre_checkout_query_id, ok, error_message)
	local body =
	{
		pre_checkout_query_id = pre_checkout_query_id,
		ok = ok
	}
	if error_message then body.error_message = error_message end
	return request('answerPreCheckoutQuery', body)
end

-- Games

function _M.sendGame(chat_id, game_short_name, disable_notification, reply_to_message_id, reply_markup)
	local body =
	{
		chat_id = chat_id,
		game_short_name = game_short_name
	}
	body = pre_msg(body, disable_notification, reply_to_message_id, reply_markup)
	request('sendGame', body)
end

function _M.setGameScore(user_id, score, force, disable_edit_message, chat_id, message_id, inline_message_id)
	local body =
	{
		user_id = user_id,
		score = score
	}
	if force then body.force = force end
	if disable_edit_message then body.disable_edit_message = disable_edit_message end
	body = pre_edit(body, chat_id, message_id, inline_message_id)
	return request('setGameScore', body)
end

function _M.getGameHighScores(user_id, chat_id, message_id, inline_message_id)
	local body = {user_id = user_id}
	body = pre_edit(body, chat_id, message_id, inline_message_id)
	return request('getGameHighScores', body)
end

return _M