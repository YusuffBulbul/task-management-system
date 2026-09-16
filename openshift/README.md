# OpenShift Deployment

Bu dizin, Task Management System projesinin OpenShift ortamında çalıştırılması için gerekli manifest dosyalarını içerir.

## Bileşenler

OpenShift kurulumu aşağıdaki bileşenleri içerir:

- Kalıcı depolama alanına sahip MongoDB
- KRaft modunda çalışan ve kalıcı depolama kullanan Apache Kafka
- Kafka topic’lerini oluşturan başlangıç job’ı
- Task Service
- Notification Service
- Analytics Service
- API Gateway
- React frontend
- OpenShift HTTPS Route

## Docker Image’ları

Uygulama aşağıdaki Docker Hub image’larını kullanır:

- `docker.io/yusuffbulbul/task-service:1.0.3`
- `docker.io/yusuffbulbul/notification-service:1.0.3`
- `docker.io/yusuffbulbul/analytics-service:1.0.3`
- `docker.io/yusuffbulbul/api-gateway:1.0.3`
- `docker.io/yusuffbulbul/task-management-frontend:1.0.3`

## Deployment Sırası

Manifest dosyaları aşağıdaki sırayla deploy edilmelidir:

1. `mongodb.yaml`
2. `kafka.yaml`
3. `backend-services.yaml`
4. `frontend.yaml`

Uygulama servisleri deploy edilmeden önce MongoDB ve Kafka’nın hazır olması gerekir.

## OpenShift Web Arayüzünden Deployment

1. Hedef OpenShift projesini seçin.
2. Üst menüde bulunan `+` simgesine tıklayın.
3. `Import YAML` sayfasını açın.
4. `mongodb.yaml` dosyasının içeriğini editöre yapıştırın.
5. `Create` butonuna tıklayın.
6. MongoDB podunun `Running` ve `Ready 1/1` olduğunu doğrulayın.
7. Aynı işlemi `kafka.yaml` dosyası için gerçekleştirin.
8. Kafka podunun `Running`, `kafka-init` job’ının ise `Completed` olduğunu doğrulayın.
9. `backend-services.yaml` dosyasını import edin.
10. Bütün backend podlarının `Running` ve `Ready 1/1` olduğunu doğrulayın.
11. `frontend.yaml` dosyasını import edin.
12. `Networking > Routes` bölümüne girin.
13. `task-management` Route’una ait HTTPS adresini açın.

## Kafka Topic’leri

`kafka-init` job’ı aşağıdaki topic’leri otomatik olarak oluşturur:

- `task-events`
- `notification-events`

## Dahili Servis Adresleri

Servisler OpenShift’in dahili DNS yapısı üzerinden iletişim kurar:

- MongoDB: `mongodb:27017`
- Kafka: `kafka:9092`
- Task Service: `task-service:8081`
- Analytics Service: `analytics-service:8083`
- API Gateway: `api-gateway-container:8084`
- Frontend: `frontend:8080`

Notification Service yalnızca Kafka üzerinden mesaj tükettiği ve yayınladığı için ayrıca bir Service kaynağına ihtiyaç duymaz.

## Kalıcı Depolama

Aşağıdaki PersistentVolumeClaim kaynakları kullanılmaktadır:

- `mongodb-data`
- `kafka-data`

Podların silinmesi veya yeniden oluşturulması kayıtlı verileri silmez. Ancak PersistentVolumeClaim kaynaklarının silinmesi ilgili verilerin kalıcı olarak kaybolmasına neden olabilir.

## Uçtan Uca Veri Akışı

Task işlemleri aşağıdaki akış üzerinden gerçekleştirilir:

```text
Kullanıcı
  → OpenShift HTTPS Route
  → Frontend ve Nginx
  → API Gateway
  → Task Service
  → MongoDB
  → Kafka task-events
  → Notification Service
  → Kafka notification-events
  → Analytics Service
  → Analytics MongoDB