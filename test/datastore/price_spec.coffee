test.uses 'Datastore.Amount',
          'Datastore.Price'

describe 'Price', ->
  it 'should require a Amounts for offered and received', ->
    expect =>
      new Price(null, amt 1)
    .to.throw "Can only create prices from Amounts"

    expect =>
      new Price(amt 1, null)
    .to.throw "Can only create prices from Amounts"

  it 'should require a non-zero, defined price', ->
    expect =>
      new Price(amt(0), amt(1))
    .to.throw "Cannot have a zero price"

    expect =>
      new Price((amt 1), (amt 0))
    .to.throw "Denominator cannot be 0"
    
  it 'should reduce the ratio when created', ->
    for _ in [1..100]
      n = amt(Math.floor(Math.random() * 10000) + 1)
      a1 = amt(Math.floor(Math.random() * 10000) + 1).multiply(n)
      a2 = amt(Math.floor(Math.random() * 10000) + 1).multiply(n)
      gcd = amt(a1.value.gcd(a2.value))
      p = new Price(a1, a2)
    
    p.offered.should.equal_amount(a1.divide(gcd))
    p.received.should.equal_amount(a2.divide(gcd))

  it 'should be able to check for equality', ->
    a = amt(Math.floor(Math.random() * 100000) + 1)
    b = amt(Math.floor(Math.random() * 100000) + 1)

    x = new Price(a, b)
    y = new Price(a, b)

    x.should.equal_price(y)
    
  describe '.inverse', ->
    beforeEach ->
      a = amt(Math.floor(Math.random() * 100000) + 1)
      b = amt(Math.floor(Math.random() * 100000) + 1)
      @price = new Price(a, b)

    it 'should be able to invert a non-zero value', ->
      inv = @price.inverse()
      
      inv.should.equal_price new Price(@price.received, @price.offered)

    it 'should be reversable', ->
      @price.inverse().inverse().should.equal_price @price

