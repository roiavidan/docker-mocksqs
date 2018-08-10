## AWS SQS Docker image

This image is based on OpenJDK 8 Alpine w/ [ElasticMQ](https://github.com/adamw/elasticmq).

It provides a local instance of [AWS SQS](https://aws.amazon.com/sqs/) that can be used for testing.

### Usage

#### 1. Docker Compose

In your `docker-compose.yml` file, add a new service like this:

```yaml
mocksqs:
  image: registry.cowbell.realestate.com.au/purchasing/docker-mocksqs
  volumes:
    - ./queues.conf:/queues.conf
  ports:
    - "9324:9324"
```

And reference this new service in your `dev` configuration:

```yaml
dev:
  ...
  links:
    - mocksqs:sqs.ap-southeast-2.amazonaws.com
```

This will create a dependency between your `dev` container and the `mocksqs` one and also add a DNS hostname to your `dev` container for resolving the `ap-southeast-2` SQS endpoint to the local mock instance.

**Note**: This is required because Ruby's AWS-SDK library seems to have a bug where defining an endpoint hostname other than the default regional ones will ignore the hostname.

#### 2. Source code (Ruby)

In your code, you should instantiate the SQS handler with the endpoint argument:

```ruby
Aws::SQS::Client.new(
  endpoint: 'http://sqs.ap-southeast-2.amazonaws.com:9324',
  verify_checksums: false
)
```

For example, with [Shoryuken](https://github.com/phstc/shoryuken), you should do something like:

`/lib/boot.rb`:
```ruby
Shoryuken.configure_server do |config|
  if ENV.fetch('USE_MOCK_SQS', '0') == '1'
    config.sqs_client = Aws::SQS::Client.new(
      endpoint: 'http://sqs.ap-southeast-2.amazonaws.com:9324',
      verify_checksums: false
    )
  end
end
```

and the evironment variable `USE_MOCK_SQS` = `1` set when running in dev mode.

#### 3. Sending messages

In order to send messages to this new queue, you could use the AWS Cli (Install [here](http://docs.aws.amazon.com/cli/latest/userguide/cli-install-macos.html) if not already installed):

```bash
$ aws --endpoint-url=http://localhost:9324 sqs send-message --queue-url=http://localhost:9324/queue/queue1 --message-body 'some message'
```

Assuming your queue is called `queue1`, of course.

### Creating queues

There are two ways to create queues:

#### Automatically

You may create queues automatically by putting them in a file called `queues.conf` and mounting it through Docker Compose (see example in section 1 above).

The `queues.conf` file looks like this:

```
queue1 {
  defaultVisibilityTimeout = 10 seconds
  delay = 5 seconds
  receiveMessageWait = 0 seconds
  deadLettersQueue {
    name = "queue1-dead-letter-queue"
    maxReceiveCount = 3 // from 1 to 1000
  }
}
queue1-dead-letter-queue { }

...
```

#### Manually

By calling the AWS Cli like this:

```bash
$ aws --endpoint-url=http://localhost:9324 sqs create-queue --queue-name queue1 --region ap-southeast-2
```

#### Examples

More examples can be seen [here](https://lobster1234.github.io/2017/04/05/working-with-localstack-command-line/#sqs).
