node-jolosrv
============

A jolokia JMX to ganglia service

## REST Interface

<table>
  <tr>
    <th>Command</th><th>Method</th><th>Url</th><th>Example</th>
  </tr>
  <tr>
    <td>version</td>
    <td>GET</td>
    <td>/</td>
    <td>curl -sL localhost:3000/</td>
  </tr>
  <tr>
    <td>list clients</td>
    <td>GET</td>
    <td>/clients/</td>
    <td>curl -sL localhost:3000/clients</td>
  </tr>
  <tr>
    <td>create client</td>
    <td>POST</td>
    <td>/clients/<code>client</code></td>
    <td>curl -sL -H "Content-Type: application/json" -X POST <br/>localhost:3000/clients/<code>client</code><br />-d '{"name":"bob","url":"http://localhost:1234/jolokia"}'</td>
  </tr>
  <tr>
    <td>update client</td>
    <td>POST</td>
    <td>/clients/<code>client</code></td>
    <td>curl -sL -H "Content-Type: application/json" -X POST <br />localhost:3000/clients/<code>client</code><br />-d '{"name":"bob","url":"http://localhost:1234/jolokia",<br/>
      "attributes": {"java.lang": {"name=ConcurrentMarkSweep,type=GarbageCollector":<br />
      {"CollectionTime":{"graph":{"host":"examplehost.domain.com",<br />
      "units":"gc/sec","slope":"both","tmax":60,"dmax":180}}}}}}'</td>
  </tr>
  <tr>
    <td>client info</td>
    <td>GET</td>
    <td>/clients/<code>client</code></td>
    <td>curl -sL localhost:3000/clients/<code>client</code></td>
  </tr>
  <tr>
    <td>all clients info</td>
    <td>GET</td>
    <td>/clients/<code>client</code></td>
    <td>curl -sL localhost:3000/clients -d 'info=true'</td>
  </tr>
  <tr>
    <td>remove attribs</td>
    <td>DELETE</td>
    <td>/clients/<code>client</code>/attributes</td>
    <td>curl -sL -X DELETE localhost:3000/clients/<code>client</code>/attributes</td>
  </tr>
  <tr>
    <td>remove client</td>
    <td>DELETE</td>
    <td>/clients/<code>client</code></td>
    <td>curl -sL -X DELETE localhost:3000/clients/<code>client</code></td>
  </tr>
</table>

## Code Status

[![build status](https://secure.travis-ci.org/seryl/node-jolosrv.png)](http://travis-ci.org/seryl/node-jolosrv)
