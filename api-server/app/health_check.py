from flask import jsonify
from datetime import datetime, timezone
import os
import logging

logger = logging.getLogger(__name__)

def add_health_endpoints(app, db_module):
    """Add health check endpoints to Flask app"""

    @app.route('/health', methods=['GET'])
    def health_check():
        """Basic health check - fast response for load balancers"""
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'service': 'vk-api'
        }), 200

    @app.route('/health/detailed', methods=['GET'])
    def detailed_health_check():
        """Detailed health check with component status"""
        health_status = {
            'status': 'healthy',
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'service': 'vk-api',
            'checks': {},
            'metrics': {}
        }

        # Database check using the actual db_connect module
        try:
            from sqlalchemy import text
            # Use the PGconnection function from db_connect
            engine = db_module.PGconnection()
            with engine.connect() as conn:
                result = conn.execute(text('SELECT 1'))
                health_status['checks']['database'] = 'ok'
        except Exception as e:
            logger.error(f"Database health check failed: {e}")
            health_status['checks']['database'] = 'failed'
            health_status['status'] = 'unhealthy'

        # Check if we have psutil for detailed metrics
        try:
            import psutil
            process = psutil.Process(os.getpid())
            memory_info = process.memory_info()
            memory_mb = memory_info.rss / 1024 / 1024

            health_status['metrics']['memory_mb'] = round(memory_mb, 2)
            health_status['metrics']['memory_percent'] = round(process.memory_percent(), 2)
            health_status['metrics']['cpu_percent'] = round(process.cpu_percent(interval=0.1), 2)
            health_status['metrics']['connections'] = len(process.connections())
            health_status['metrics']['threads'] = process.num_threads()

            # Disk usage
            disk_usage = psutil.disk_usage('/')
            health_status['metrics']['disk_percent'] = round(disk_usage.percent, 2)

            if memory_mb > 500:
                health_status['status'] = 'degraded'
                health_status['checks']['memory'] = 'high'
            else:
                health_status['checks']['memory'] = 'ok'
        except ImportError:
            # psutil not installed, just basic metrics
            health_status['metrics']['note'] = 'Install psutil for detailed metrics'
        except Exception as e:
            logger.error(f"Metrics collection failed: {e}")
            health_status['checks']['metrics'] = 'failed'

        # Return appropriate status code
        if health_status['status'] == 'unhealthy':
            return jsonify(health_status), 503
        else:
            return jsonify(health_status), 200

    @app.route('/health/metrics', methods=['GET'])
    def metrics_endpoint():
        """Metrics in Datadog format"""
        metrics = {
            'vk.api.status': 1,
            'vk.api.timestamp': int(datetime.now(timezone.utc).timestamp())
        }

        try:
            import psutil
            process = psutil.Process(os.getpid())

            metrics.update({
                'vk.api.memory.rss': process.memory_info().rss,
                'vk.api.memory.percent': process.memory_percent(),
                'vk.api.cpu.percent': process.cpu_percent(interval=0.1),
                'vk.api.connections.count': len(process.connections()),
                'vk.api.threads.count': process.num_threads(),
                'vk.api.uptime.seconds': int((datetime.now() - datetime.fromtimestamp(process.create_time())).total_seconds())
            })

            # Check database
            try:
                from sqlalchemy import text
                engine = db_module.PGconnection()
                with engine.connect() as conn:
                    conn.execute(text('SELECT 1'))
                metrics['vk.api.database.status'] = 1
            except:
                metrics['vk.api.database.status'] = 0

        except ImportError:
            metrics['vk.api.metrics.available'] = 0
        except Exception as e:
            logger.error(f"Metrics endpoint failed: {e}")
            metrics['vk.api.metrics.error'] = 1

        return jsonify(metrics), 200