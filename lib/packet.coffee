require('buffertools')
sprintf = require('sprintf').sprintf

HEADER_LENGTH = 8

TYPE =
  RPC_REQUEST: 0x03,
  TABULAR_RESULT: 0x04,
  LOGIN7: 0x10,
  PRELOGIN: 0x12

typeByValue = {}
for name, value of TYPE
  typeByValue[value] = name

STATUS =
  NORMAL: 0x00,
  EOM: 0x01,                      # End Of Message (last packet).
  IGNORE: 0x02,                   # EOM must also be set.
  RESETCONNECTION: 0x08,
  RESETCONNECTIONSKIPTRAN: 0x10

OFFSET =
  Type: 0,
  Status: 1,
  Length: 2,
  SPID: 4,
  PacketID: 6,
  Window: 7

DEFAULT_SPID = 0;
DEFAULT_PACKETID = 0;
DEFAULT_WINDOW = 0;

class Packet
  constructor: (typeOrBuffer) ->
    if typeOrBuffer instanceof Buffer
      @buffer = typeOrBuffer
    else
      type = typeOrBuffer

      @buffer = new Buffer(HEADER_LENGTH)

      @buffer.writeUInt8(type, OFFSET.Type)
      @buffer.writeUInt8(STATUS.NORMAL, OFFSET.Status)
      @buffer.writeUInt16BE(DEFAULT_SPID, OFFSET.SPID)
      @buffer.writeUInt8(DEFAULT_PACKETID, OFFSET.PacketID)
      @buffer.writeUInt8(DEFAULT_WINDOW, OFFSET.Window)

      @setLength()

  setLength: ->
    @buffer.writeUInt16BE(@buffer.length, OFFSET.Length)

  length: ->
    @buffer.readUInt16BE(OFFSET.Length)

  setLast: ->
    status = @buffer.readUInt8(OFFSET.Status) | STATUS.EOM
    @buffer.writeUInt8(status, OFFSET.Status)
    @

  isLast: ->
    @buffer.readUInt8(OFFSET.Status) & STATUS.EOM

  addData: (data) ->
    @buffer = new Buffer(@buffer.concat(data))
    @setLength()
    @

  data: ->
    @buffer.slice(HEADER_LENGTH)

  statusAsString: ->
    status = @buffer.readUInt8(OFFSET.Status)
    statuses = for name, value of STATUS
      if status & value
        name
    statuses.join(' ').trim() 

  headerToString: (indent) ->
    text = sprintf('header - type:0x%02X(%s), status:0x%02X(%s), length:0x%04X, spid:0x%04X, packetId:0x%02X, window:0x%02X',
      @buffer.readUInt8(OFFSET.Type), typeByValue[@buffer.readUInt8(OFFSET.Type)],
      @buffer.readUInt8(OFFSET.Status), @statusAsString(),
      @buffer.readUInt16BE(OFFSET.Length),
      @buffer.readUInt16BE(OFFSET.SPID),
      @buffer.readUInt8(OFFSET.PacketID),
      @buffer.readUInt8(OFFSET.Window),
    )

    indent + text

exports.Packet = Packet
exports.TYPE = TYPE
