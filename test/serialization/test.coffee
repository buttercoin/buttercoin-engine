Account = require '../../lib/datastore/account'
Amount = require '../../lib/datastore/amount'
Order = require '../../lib/datastore/order'
BalanceSheet = require '../../lib/datastore/balancesheet'
Book = require '../../lib/datastore/book'
Market = require '../../lib/datastore/market'
SuperMarket = require '../../lib/datastore/supermarket'
DataStore = require '../../lib/datastore/datastore'

ds = new DataStore()

b = ds.balancesheet

a = b.get_account('Test')
a.credit 'USD', Amount.take('100')

a.create_order('USD', Amount.take('10'), 'BTC', Amount.take('1'))
a.create_order('USD', Amount.take('10'), 'BTC', Amount.take('1'))
o = a.create_order('USD', Amount.take('10'), 'BTC', Amount.take('1'))

data = o.create_snapshot()
Order.load_snapshot(data)
#console.log Order.load_snapshot(data)
data = a.create_snapshot()
Account.load_snapshot(data)
data = b.create_snapshot()
BalanceSheet.load_snapshot(data)
#console.log BalanceSheet.load_snapshot(data)

supermarket = ds.supermarket
market = supermarket.get_market('BTC', 'USD')
market.add_order(o)

data = market.create_snapshot()
Market.load_snapshot(data)

data = supermarket.create_snapshot()
SuperMarket.load_snapshot(data)

data = ds.create_snapshot()
console.log data
console.log DataStore.load_snapshot(data)
