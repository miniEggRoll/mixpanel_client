mixpanel_node
=============

mixpanel track and data export client for node

## How to use

```
mp = require 'mixpanel_client'

config = 
  api_key: '18b972e99fb854b32b5933a7b2698380'
  secret: 'ee4ee84bb3ebc2f23dee26c85075df6e'
  mixpanelToken: '2af8b6e71b506634a3cc5691bf99aee6'
  
project = mp config
```

## api
- events
- eventProp
- funnels
- annotations 
- segmentation
- retention
- engage
- raw

For detail documentations check offical [doc](https://mixpanel.com/docs/api-documentation/data-export-api)
