module.exports = (App, config, Express) ->
  Express.Router()
  .get '/', (req, res) -> res.render 'index'
    
