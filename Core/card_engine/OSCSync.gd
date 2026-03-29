# OSCSync.gd (挂载在全局单例或 CombatResolver 上)
extends Node

var udp := PacketPeerUDP.new()
const TD_IP = "127.0.0.1"
const TD_PORT = 7000

func _ready():

	SignalBus.card_played.connect(_on_card_played)

func _on_card_played(card_data: Dictionary):
  
	match card_data.suit:
		"Red": 
			send_trigger("/trigger/point")
		"Green": 
			send_trigger("/trigger/line")
		"Blue": 
			send_trigger("/trigger/plane")

func send_trigger(address: String):
	# 构建一个简单的 OSC 消息块 (Address + Value 1.0)
	# 注意：这里建议发送 1.0 作为一个脉冲
	var msg = [address, 1.0] 
	# 此处假设你使用了简单的 UDP 封装或插件
	udp.set_dest_address(TD_IP, TD_PORT)
	udp.put_packet(OSCHelper.encode(msg))
