[![build status](https://secure.travis-ci.org/seryl/node-jolosrv.png)](http://travis-ci.org/seryl/node-jolosrv)
node-jolosrv
============

A jolokia JMX to ganglia service

## REST Interface

Getting the version
```
curl -sL localhost:3000
```

Getting the list of clients
```
curl -sL localhost:3000/clients
```

Creating a client
```
curl -sL -H "Content-Type: application/json" -X POST localhost:3000/clients -d '
{
  "name": "zoidberg",
  "url": "http://localhost:1234/jolokia"
}'
```

Updating a client
```
curl -sL -H "Content-Type: application/json" -X POST localhost:3000/clients -d '
{
  "name": "zoidberg",
  "url": "http://localhost:1234/jolokia",
  "attributes": {
    "java.lang": {
      "name=ConcurrentMarkSweep,type=GarbageCollector": {
        "CollectionTime": {
          "graph": {
            "host": "examplehost.domain.com",
            "units": "gc/sec",
            "slope": "both",
            "tmax": 60,
            "dmax": 180
          }
        }
      }
    }
  }
}'
```

Getting detailed information for a client
```
curl -sL localhost:3000/clients/zoidberg
```

Getting detailed information for all clients
```
curl -sL localhost:3000/clients/zoidberg -d 'info=true'
```

Removing attributes for a client
```
curl -sL -X DELETE localhost:3000/clients/zoidberg/attributes
```

Removing a client
```
curl -sL -X DELETE localhost:3000/clients/zoidberg
```
