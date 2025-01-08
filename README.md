# Cortex Neuron SDK for Go

This is the official Cortex Neuron SDK for Go. It provides a simple way to interact with and extend your Cortex instance.

## Getting started

To run the Cortex SDK you need to get the Neuron Agent via Docker:

```
docker pull ghcr.io/cortexapps/cortex-neuron-agent:latest
```

Then to scaffold a Go project:

```
docker run -it --rm -v "$(pwd):/src" ghcr.io/cortexapps/cortex-neuron-agent:latest init --language go my-go-neuron project
```

This will create a new directory `my-go-neuron` with a Go project scaffolded in the current directory.

## Running locally

To run your project, first start the agent Docker container like:

```
docker run -it --rm -p "50051:50051" -e "DRYRUN=true" ghcr.io/cortexapps/cortex-neuron-agent:latest serve
```

This is `DRYRUN` mode that prints what it would have called, to run against the Cortex API remove the `DRYRUN` environment variable and add `-e "CORTEX_API_TOKEN=$CORTEX_API_TOKEN`.  Be sure to export your token first, e.g. `export CORTEX_API_TOKEN=your-token`.


## Adding handlers

To add a handler, open `main.go` and create a function:

```go

// Here we have our example handler that will be called every one second
func myExampleIntervalHandler(client pb.CortexApiClient) interface{} {

	// here you would do some operations that then push data to the cortex api
	//
	// JSON payload to send to the Cortex API is like:
	// {
	// 	"values": {
	// 	  "service-tag": [
	// 		{
	// 		  "key": "k1",
	// 		  "value": "v1"
	// 		},
	// 		{
	// 		  "key": "k2",
	// 		  "value": "v2"
	// 		}
	// 	  ],
	// 	}

	payload := map[string]interface{}{
		"values": map[string]interface{}{
			"my-service": []interface{}{
				map[string]string{
					"key":   "my-custom-key",
					"value": "my-custom-value",
				},
			},
		},
	}

	json, err := json.Marshal(payload)
	if err != nil {
		ctx.Logger().Error("Error marshalling json", zap.Error(err))
		return nil
	}

	ctx.CortexJsonApiCall(context.Background(), "PUT","/api/v1/catalog/custom-data", string(json))

	log.Println("myExampleIntervalHandle called!")
	return nil
}

```

Then register it with the agent:

```go

agentClient := neuron.NewNeuronAgent()

_, err := agentClient.RegisterHandler(myExampleIntervalHandler,
		neuron.WithInvokeOption(pb.HandlerInvokeType_RUN_INTERVAL, "1s"),
	)
agentClient.Run(context.Background())
```

Now start the agent in a separate terminal:
```
make run-agent
```

And run your project:
```
go run main.go
```

This will begin executing your handler every second.





