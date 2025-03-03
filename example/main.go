package main

import (
	"context"
	"encoding/json"
	"log"
	"time"

	"github.com/cortexapps/axon"
	pb "github.com/cortexapps/axon/.generated/proto/github.com/cortexapps/axon"
	"go.uber.org/zap"
)

func main() {

	// create our agent client and register a handler
	agentClient := axon.NewAxonAgent()

	// this handler will be invoked every 1 second
	_, err := agentClient.RegisterHandler(myExampleIntervalHandler,
		axon.WithTimeout(time.Minute),
		axon.WithInvokeOption(
			pb.HandlerInvokeType_RUN_INTERVAL, "1s",
		),
	)

	if err != nil {
		log.Fatalf("Error registering handler: %v", err)
	}

	// Start the run process.  This will block and stream invocations
	ctx := context.Background()
	agentClient.Run(ctx)

}

// Here we have our example handler that will be called every one second
func myExampleIntervalHandler(ctx axon.HandlerContext) interface{} {

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

	ctx.CortexJsonApiCall("PUT", "/api/v1/catalog/custom-data", string(json))

	ctx.Logger().Info("Hello from myExampleIntervalHandler!")
	return nil
}
