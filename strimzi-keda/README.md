## Test code for Strimzi Kafka and KEDA

**Step 1**: Comment out the code for the kafka batch job producer

```
resource "kubectl_manifest" "kafka-producer-job" {
  yaml_body = file("${path.module}/manifest/kafka_producer.yaml")
}
```

**Step 2**: Run terraform plan and apply. We will see a strimzi cluster created with topic `my-topic`, a kafka consumer app deployment

```
terraform init
terraform plan
terraform apply
```
HPA is also deployed
```
❯ k get hpa
NAME                          REFERENCE                   TARGETS             MINPODS   MAXPODS   REPLICAS   AGE
keda-hpa-kafka-scaledobject   Deployment/kafka-consumer   <unknown>/5 (avg)   1         100       0          3h22m
```
We can see the metrics from metric apiserver
```
❯ kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/default/s0-kafka-my-topic?labelSelector=scaledobject.keda.sh%2Fname%3Dkafka-scaledobject" | jq
{
  "kind": "ExternalMetricValueList",
  "apiVersion": "external.metrics.k8s.io/v1beta1",
  "metadata": {},
  "items": [
    {
      "metricName": "s0-kafka-my-topic",
      "metricLabels": null,
      "timestamp": "2023-11-25T11:34:18Z",
      "value": "0"
    }
  ]
}
```

**Step 3**: Uncomment the code block from step 1 and run terraform plan and apply again.
You will see a producer job being deployed. Scaled object will scale from 0 to 1 replicas and HPA will handle the scaling from 1 to 5 replica

```
❯ k describe hpa keda-hpa-kafka-scaledobject
Name:               keda-hpa-kafka-scaledobject
Namespace:          default
Labels:             app.kubernetes.io/managed-by=keda-operator
                    app.kubernetes.io/name=keda-hpa-kafka-scaledobject
                    app.kubernetes.io/part-of=kafka-scaledobject
                    app.kubernetes.io/version=2.12.0
                    scaledobject.keda.sh/name=kafka-scaledobject
Annotations:        autoscaling.alpha.kubernetes.io/conditions:
                      [{"type":"AbleToScale","status":"True","lastTransitionTime":"2023-11-25T10:48:46Z","reason":"ReadyForNewScale","message":"recommended size...
                    autoscaling.alpha.kubernetes.io/current-metrics:
                      [{"type":"External","external":{"metricName":"s0-kafka-my-topic","metricSelector":{"matchLabels":{"scaledobject.keda.sh/name":"kafka-scale...
                    autoscaling.alpha.kubernetes.io/metrics:
                      [{"type":"External","external":{"metricName":"s0-kafka-my-topic","metricSelector":{"matchLabels":{"scaledobject.keda.sh/name":"kafka-scale...
CreationTimestamp:  Sat, 25 Nov 2023 08:11:08 +0000
Reference:          Deployment/kafka-consumer
Min replicas:       1
Max replicas:       100
Deployment pods:    5 current / 5 desired
Events:
  Type     Reason             Age                  From                       Message
  ----     ------             ----                 ----                       -------
  Normal   SuccessfulRescale  81m                  horizontal-pod-autoscaler  New size: 1; reason: All metrics below target
  Warning  FailedGetScale     22m                  horizontal-pod-autoscaler  Unauthorized
  Normal   SuccessfulRescale  3m48s (x2 over 91m)  horizontal-pod-autoscaler  New size: 4; reason: external metric s0-kafka-my-topic(&LabelSelector{MatchLabels:map[string]string{scaledobject.keda.sh/name: kafka-scaledobject,},MatchExpressions:[]LabelSelectorRequirement{},}) above target
  Normal   SuccessfulRescale  3m33s (x2 over 90m)  horizontal-pod-autoscaler  New size: 5; reason: external metric s0-kafka-my-topic(&LabelSelector{MatchLabels:map[string]string{scaledobject.keda.sh/name: kafka-scaledobject,},MatchExpressions:[]LabelSelectorRequirement{},}) above target
```

To check the consumer group lag. We can run the following command
```
# Expose the service to local
minikube service test-cluster-kafka-external4-bootstrap --url

❯ bin/kafka-consumer-groups.sh --bootstrap-server 192.168.49.2:32118 --describe --group my-kafka-consumer
GROUP             TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID                                                       HOST            CLIENT-ID
my-kafka-consumer my-topic        0          2228364         2399831         171467          consumer-my-kafka-consumer-1-4ada33da-308c-42a7-932b-bd2691ed7598 /10.244.0.87    consumer-my-kafka-consumer-1
my-kafka-consumer my-topic        3          2210351         2388936         178585          consumer-my-kafka-consumer-1-cd10f502-b24e-4af1-a5ba-4c8fde12f618 /10.244.0.84    consumer-my-kafka-consumer-1
my-kafka-consumer my-topic        2          2220899         2427129         206230          consumer-my-kafka-consumer-1-97d3577b-0df4-40f3-951c-35ad2ec07040 /10.244.0.88    consumer-my-kafka-consumer-1
my-kafka-consumer my-topic        4          2190964         2400632         209668          consumer-my-kafka-consumer-1-ec8d6b27-1ae1-42a0-8345-99884f006300 /10.244.0.83    consumer-my-kafka-consumer-1
my-kafka-consumer my-topic        1          2210001         2383472         173471          consumer-my-kafka-consumer-1-52ebe974-5131-47ff-b8b8-7283f032c619 /10.244.0.86    consumer-my-kafka-consumer-1

```

**Step 4**: Continue monitoring. Once the offset lag reaches 0 for all partitions, HPA will scale down from 5 to 1 and KEDA will scale from 1 to 0 replicas
