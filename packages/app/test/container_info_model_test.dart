import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContainerInfo', () {
    test('fromJson parses a full container object', () {
      final json = <String, dynamic>{
        'id': 'cont-123',
        'owner_id': 'owner-1',
        'swarm_service_id': 'svc-abc',
        'image': 'nginx:alpine',
        'cpu_millis': 512,
        'memory_mb': 1024,
        'storage_gb': 10,
        'env': {'KEY': 'val'},
        'state': 'RUNNING',
        'host_port': 8080,
        'node_ip': '10.0.0.1',
        'expires_at': '2026-07-02T12:00:00.000Z',
        'created_at': '2026-07-01T10:00:00.000Z',
        'updated_at': '2026-07-01T10:30:00.000Z',
      };

      final info = ContainerInfo.fromJson(json);

      expect(info.id, 'cont-123');
      expect(info.ownerId, 'owner-1');
      expect(info.swarmServiceId, 'svc-abc');
      expect(info.image, 'nginx:alpine');
      expect(info.cpuMillis, 512);
      expect(info.memoryMb, 1024);
      expect(info.storageGb, 10);
      expect(info.env, {'KEY': 'val'});
      expect(info.state, 'RUNNING');
      expect(info.hostPort, 8080);
      expect(info.nodeIp, '10.0.0.1');
      expect(info.isRunning, true);
      expect(info.isPending, false);
      expect(info.isTerminal, false);
    });

    test('fromJson parses minimal fields with defaults', () {
      final json = <String, dynamic>{
        'id': 'cont-456',
        'owner_id': 'owner-2',
        'image': 'python:3.12',
        'state': 'STOPPED',
        'expires_at': '2026-07-01T10:00:00.000Z',
        'created_at': '2026-07-01T08:00:00.000Z',
        'updated_at': '2026-07-01T09:00:00.000Z',
      };

      final info = ContainerInfo.fromJson(json);

      expect(info.id, 'cont-456');
      expect(info.state, 'STOPPED');
      expect(info.cpuMillis, 0);
      expect(info.memoryMb, 0);
      expect(info.storageGb, 0);
      expect(info.env, <String, String>{});
      expect(info.isRunning, false);
      expect(info.isStopped, true);
      expect(info.isTerminal, true);
    });
  });
}
