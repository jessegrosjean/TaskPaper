DateTime = require '../src/date-time'
should = require('chai').should()

describe 'DateTime', ->

  it 'should convert date time to absolute date time', ->
    DateTime.format('this feb').substr(4).should.match(/-02-01/)
    DateTime.format('this feb +5h').substr(4).should.match(/-02-01 05:00/)
    DateTime.format('this feb +5h +10m').substr(4).should.match(/-02-01 05:10/)
    DateTime.format('this feb +5h +10m 20ms').substr(4).should.match(/-02-01 05:10:00:020/)
    DateTime.format('2016-02-01').substr(4).should.equal('-02-01')
    DateTime.format('this may').substr(4).should.equal('-05-01')
    DateTime.format('2016-05-01').substr(4).should.equal('-05-01')
    DateTime.format('this may at 9am').substr(4).should.equal('-05-01 09:00')
    DateTime.format('this may 1 9pm').substr(4).should.equal('-05-01 21:00')
    DateTime.format('this may at 9pm -10m').substr(4).should.equal('-05-01 20:50')
    DateTime.format('2016-W51-4').should.equal('2016-12-22')
    DateTime.format(new Date(2016, 1, 1)).should.equal('2016-02-01')
    DateTime.format(new Date(2016, 5, 1)).should.equal('2016-06-01')

  it 'should round trip now', ->
    now = DateTime.parse('now')
    DateTime.parse(DateTime.format(now)).should.eql(now)
