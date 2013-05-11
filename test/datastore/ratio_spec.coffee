test.uses 'Datastore.Amount',
          'Datastore.Ratio'

describe 'Ratio', ->
  it 'should require a defined ratio', ->
    expect =>
      new Ratio((amt 1), (amt 0))
    .to.throw "Denominator cannot be 0"
    
  it 'should reduce the ratio when created', ->
    for _ in [1..100]
      n = amt(Math.floor(Math.random() * 10000) + 1)
      a1 = amt(Math.floor(Math.random() * 10000) + 1).multiply(n)
      a2 = amt(Math.floor(Math.random() * 10000) + 1).multiply(n)
      gcd = amt(a1.value.gcd(a2.value))
      p = new Ratio(a1, a2)
    
    p.offered.should.equal_amount(a1.divide(gcd))
    p.received.should.equal_amount(a2.divide(gcd))

  it 'should be able to check for equality', ->
    a = amt(Math.floor(Math.random() * 100000) + 1)
    b = amt(Math.floor(Math.random() * 100000) + 1)

    x = new Ratio(a, b)
    y = new Ratio(a, b)

    x.should.equal_ratio(y)

  it 'should be able to compare ratios', ->
    a = new Ratio(amt(1), amt(4))
    b = new Ratio(amt(2), amt(4))
    c = new Ratio(amt(3), amt(4))

    a.compareTo(b).should.be.lt 0
    b.compareTo(b).should.equal 0
    c.compareTo(b).should.be.gt 0
    
  describe '.inverse', ->
    beforeEach ->
      a = amt(Math.floor(Math.random() * 100000) + 1)
      b = amt(Math.floor(Math.random() * 100000) + 1)
      @ratio = new Ratio(a, b)

    it 'should be able to invert a non-zero value', ->
      inv = @ratio.inverse()
      
      inv.should.equal_ratio new Ratio(@ratio.received, @ratio.offered)

    it 'should be reversable', ->
      @ratio.inverse().inverse().should.equal_ratio @ratio

