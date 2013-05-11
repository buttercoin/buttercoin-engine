test.uses 'Datastore.Amount',
          'Datastore.Ratio'

randomAmount = (upper=10000)->
  amt(Math.floor(Math.random() * upper) + 1)

describe 'Ratio', ->
  it 'should require a defined ratio', ->
    expect =>
      new Ratio((amt 1), (amt 0))
    .to.throw "Denominator cannot be 0"
    
  it 'should reduce the ratio when created', ->
    for _ in [1..100]
      n = randomAmount()
      a1 = randomAmount().multiply(n)
      a2 = randomAmount().multiply(n)
      gcd = amt(a1.value.gcd(a2.value))
      p = new Ratio(a1, a2)
    
      p.numerator.should.equal_amount(a1.divide(gcd))
      p.denominator.should.equal_amount(a2.divide(gcd))

  it 'should be able to check for equality', ->
    a = randomAmount()
    b = randomAmount()

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
    
  describe '#math', ->
    beforeEach ->
      @a = randomAmount(10)
      @b = randomAmount(10)
      @c = randomAmount(10)
      @d = randomAmount(10)

      @x = new Ratio(@a, @b)
      @y = new Ratio(@c, @d)

    it 'should be able to add ratios', ->
      top = @a.multiply(@d).add(@c.multiply(@b))
      bot = @b.multiply(@d)
      expected = new Ratio(top, bot)

      result = @x.add(@y)
      result.compareTo(@x).should.be.gt 0
      result.compareTo(@y).should.be.gt 0
      result.should.equal_ratio(expected)
     
    it 'should be able to subtract ratios', ->
      top = @a.multiply(@d).subtract(@c.multiply(@b))
      bot = @b.multiply(@d)
      expected = new Ratio(top, bot)

      result = @x.subtract(@y)
      result.compareTo(@x).should.be.lt 0
      result.add(@y).should.equal_ratio(@x)
      result.should.equal_ratio(expected)

    it 'should be able to multiply ratios', ->
      top = @a.multiply(@c)
      bot = @b.multiply(@d)
      expected = new Ratio(top, bot)

      result = @x.multiply(@y)
      result.should.not.equal_amount(new Ratio())
      result.should.equal_ratio(expected)

    it 'should be able to divide ratios', ->
      top = @a.multiply(@d)
      bot = @b.multiply(@c)
      expected = new Ratio(top, bot)

      result = @x.divide(@y)
      result.should.not.equal_amount(new Ratio())
      result.should.equal_ratio(expected)

    it 'should be able to add an amount', ->
      @y = new Ratio(@c, Amount.one)
      top = @a.add(@c.multiply(@b))
      bot = @b
      expected = new Ratio(top, bot)

      result = @x.add(@c)
      result.compareTo(@x).should.be.gt 0
      result.compareTo(@y).should.be.gt 0
      result.should.equal_ratio(expected)

    it 'should be able to subtract an amount', ->
      @y = new Ratio(@c, Amount.one)
      top = @a.subtract(@c.multiply(@b))
      bot = @b
      expected = new Ratio(top, bot)

      result = @x.subtract(@c)
      result.compareTo(@x).should.be.lt 0
      result.should.equal_ratio(expected)

    xit 'should be able to multiply an amount'
    xit 'should be able to divide an amount'

  describe '.inverse', ->
    beforeEach ->
      a = randomAmount()
      b = randomAmount()
      @ratio = new Ratio(a, b)

    it 'should be able to invert a non-zero value', ->
      inv = @ratio.inverse()
      
      inv.should.equal_ratio new Ratio(@ratio.denominator, @ratio.numerator)

    it 'should be reversable', ->
      @ratio.inverse().inverse().should.equal_ratio @ratio

