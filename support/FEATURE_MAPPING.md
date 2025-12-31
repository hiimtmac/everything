# Everything Technology Feature Mapping

This document maps each technology from the TECHNOLOGY.md wishlist to specific features and use cases in the Everything coffee ordering system. This is intentionally over-engineered for learning purposes.

---

## 1. Real-Time Communication Technologies

### WebSockets

**Use Cases:**

- **Barista Dashboard (macOS/iPadOS):** Real-time order queue updates as new orders arrive without polling
- **Customer Order Tracking (iOS/watchOS):** Live updates when barista accepts, starts making, or completes your order
- **Kitchen Display (tvOS):** Real-time order queue that updates instantly when orders are placed or status changes
- **Multi-device Sync:** When you modify favorites on macOS, it instantly reflects on your iPhone/Watch
- **Collaborative Ordering:** Family members can see each other adding items to a group order in real-time

### Server-Sent Events (SSE)

**Use Cases:**

- **Order Status Feed (iOS):** One-way server→client stream for order status updates (simpler than WebSocket for read-only updates)
- **Menu Updates (All Apps):** When admin updates menu/pricing on macOS, all connected devices receive instant notification
- **Loyalty Points Events (iOS):** Stream achievement unlocks and loyalty point changes as they happen
- **System Announcements:** Broadcast messages like "Last call for orders before closing" to all connected devices
- **Leaderboard Updates (tvOS):** Stream weekly rankings changes without constant polling

### HTTP Streaming

**Use Cases:**

- **Order Receipt Generation (iOS):** Stream PDF generation progress as large monthly receipts compile
- **Bulk Export (macOS):** Stream order history CSV export for large date ranges without timeout
- **Image Upload (iPadOS POS):** Stream drink photos for menu items with progress feedback
- **Analytics Reports (macOS):** Stream large analytics queries results progressively

### QUIC Protocol

**Use Cases:**

- **Faster Initial Connections (All Mobile Apps):** Reduced latency for first request when opening app
- **Better Mobile Performance:** Connection migration when switching between WiFi/cellular in house
- **Unreliable Network Resilience:** Maintain connections when family members move around house with devices
- **Multiplexed Requests:** Multiple concurrent API calls without head-of-line blocking

---

## 2. API Query Patterns

### GraphQL

**Use Cases:**

- **Mobile App Optimized Queries:** Fetch user profile + favorite drinks + loyalty status + active orders in single request
- **Smart Widgets:** Widget queries only request data needed for specific widget type (lock screen vs home screen)
- **Flexible Reports (macOS):** Reporting interface lets admin customize exactly which fields to include
- **Over-fetching Prevention:** iOS app requests only needed fields for different screen sizes (iPhone vs iPad)
- **Schema Evolution:** Add new customer fields without breaking existing mobile apps
- **Subscription Support:** GraphQL subscriptions for real-time order updates (alternative to WebSocket)

---

## 3. gRPC Communication Patterns

### Unary RPC (Request/Response)

**Use Cases:**

- **Place Order:** Client sends complete order → server returns order confirmation
- **Get Menu:** Client requests menu → server returns full menu catalog
- **Update Profile:** Client sends profile changes → server confirms update
- **Check Loyalty Balance:** Client requests points → server returns balance

### Server Streaming RPC

**Use Cases:**

- **Menu Search:** Client requests "lattes" → server streams matching items as it searches inventory
- **Order History:** Client requests last 100 orders → server streams them progressively
- **Preparation Steps Stream:** Barista app requests order details → server streams each preparation step
- **Daily Stats Stream:** macOS admin app requests stats → server streams metrics as computed

### Client Streaming RPC

**Use Cases:**

- **Batch Order Import:** macOS admin streams CSV rows → server imports and returns summary
- **Image Upload:** iPadOS POS streams drink photo chunks → server confirms upload
- **Bulk Favorite Import:** Client streams list of favorite drinks → server adds all and returns count
- **Analytics Events:** iOS app streams usage events → server batches and acknowledges

### Bidirectional Streaming RPC

**Use Cases:**

- **Live Chat with Barista:** Customer and barista stream messages back and forth about custom order
- **Collaborative Order Building:** Multiple family members stream item additions to shared group order
- **Real-time Inventory Sync:** POS streams sales → server streams low-stock alerts back
- **Interactive Troubleshooting:** Customer streams error logs → support system streams diagnostic steps

---

## 4. Push Notifications (APNS)

### Standard Notifications

**Use Cases:**

- **Order Ready:** "Your caramel macchiato is ready for pickup!"
- **Order Accepted/Declined:** Barista responses to order requests
- **Loyalty Milestones:** "Congratulations! You earned a free drink!"
- **Daily Summary:** "You ordered 3 drinks today (2 lattes, 1 cappuccino)"
- **Menu Updates:** "New seasonal drinks added to menu"
- **Abandoned Order:** "You have items in cart" reminder after 30 minutes
- **Low Balance Warning:** "Your loyalty points will expire soon"

### Background Notifications (Silent Push)

**Use Cases:**

- **Pre-warm Data:** Silent push triggers app to refresh menu before user opens it
- **Sync Favorites:** Update favorite drinks cache in background
- **CoreML Model Updates:** Trigger download of updated recommendation model
- **Cache Invalidation:** Clear stale cached data when menu changes

### Rich Notifications

**Use Cases:**

- **Order with Images:** Notification shows photo of your drink being prepared
- **Custom Actions:** "Reorder this drink" / "Mark as picked up" buttons
- **Progress Updates:** Notification updates in place as drink preparation progresses

### Live Activities Integration

**Use Cases:**

- **APNS updates Live Activity:** Server pushes updates to Live Activity showing order progress on lock screen/Dynamic Island

---

## 5. Observability & Monitoring

### Distributed Tracing (OpenTelemetry)

**Use Cases:**

- **End-to-End Request Tracking:** Trace order from iPhone tap → Hummingbird → Order Service → Customer Service → Temporal → Kafka → Database
- **Performance Bottleneck Identification:** See which service adds latency (gRPC call to Customer Service takes 200ms)
- **Error Source Debugging:** Trace failed order back to exact line in Order Service that threw exception
- **Cross-Service Transaction Tracking:** Follow Temporal workflow execution across multiple service calls

### Service Dependency Mapping

**Use Cases:**

- **Architecture Visualization:** Auto-generate diagrams showing which services talk to which
- **Impact Analysis:** "If Order Service goes down, what breaks?"
- **Cascade Failure Detection:** Identify when Customer Service slowdown affects Order Service

### Latency Breakdown & Error Tracing

**Use Cases:**

- **SLO Monitoring:** Alert when P95 order placement latency exceeds 500ms
- **gRPC Method Performance:** Compare latency of different RPC methods
- **Database Query Optimization:** Identify slow PostgreSQL queries from traces
- **Cache Hit/Miss Correlation:** Trace showing Valkey cache miss caused database query

### Log Aggregation with Search/Filtering

**Use Cases:**

- **Error Investigation:** Search logs for "order_id:12345" across all services
- **User Session Debugging:** Filter logs by "user_id:hiimtmac" to see all their actions
- **Performance Analysis:** Query logs for requests >1s response time
- **Security Auditing:** Search authentication logs for failed login attempts

### Visualization (Grafana/Prometheus)

**Use Cases:**

- **Real-time Metrics Dashboard:** Live graphs of orders/minute, active users, cache hit rate
- **Service Health:** CPU/memory usage per service, pod restarts, request rates
- **Business Metrics:** Daily order volume, most popular drinks, peak ordering times
- **SLA Tracking:** Uptime percentages, error rates, latency percentiles
- **Kafka Lag Monitoring:** Consumer lag, message throughput, partition health
- **Temporal Workflow Metrics:** Active workflows, completion rates, task queue depth
- **Custom Alerts:** Slack notification when error rate >1%, weekly summary report

---

## 6. Authentication & Authorization Methods

### WebAuthn/Passkeys

**Use Cases:**

- **Primary Login (iOS/macOS):** Face ID/Touch ID for passwordless sign-in
- **Secure POS Access (iPadOS):** Fingerprint auth for barista mode on tablet
- **Account Recovery:** Use passkey on second device to recover account
- **Step-up Authentication:** Require passkey for sensitive actions (view payment history, delete account)

### JWT (JSON Web Tokens)

**Use Cases:**

- **Mobile Session Management:** Store JWT in keychain, include in API requests
- **Stateless Authentication:** Server validates JWT signature without database lookup
- **Role-Based Access:** JWT claims specify "customer" vs "barista" vs "admin" role
- **Short-lived Tokens:** 15-minute access tokens with refresh token pattern
- **Device Binding:** JWT includes device fingerprint for additional security

### TOTP/OTP (Time-based One-Time Passwords)

**Use Cases:**

- **2FA Option:** Users can enable Google Authenticator for additional security
- **SMS Backup:** SMS OTP for users without authenticator app
- **Account Setup:** One-time code sent via email for initial account verification
- **Suspicious Activity:** Require OTP when logging in from new device

### SRP (Secure Remote Password)

**Use Cases:**

- **Zero-Knowledge Authentication:** Verify password without server storing it
- **Enhanced Privacy:** Server never sees plaintext password, even during registration
- **Alternative to Passkeys:** For users who prefer password-based auth but want maximum security

### Basic Auth

**Use Cases:**

- **Admin Scripts:** Simple auth for backend automation scripts
- **Health Check Endpoints:** Basic auth protecting Prometheus metrics endpoints
- **Development Tools:** Quick auth for internal tools during development

### Session Management

**Use Cases:**

- **Web Dashboard Sessions:** Cookie-based sessions for macOS web admin panel
- **Remember Me:** Extended sessions for trusted devices
- **Multi-device Sessions:** View/revoke active sessions from all devices
- **Session Timeout:** Auto-logout after 30 minutes inactivity

### OAuth2/OIDC - Sign in with Apple (Future)

**Use Cases:**

- **Guest Ordering:** Visitors can use Apple ID for one-time guest orders
- **Privacy First:** Hide email with Apple's relay service
- **Quick Onboarding:** Automatic account creation from Apple ID
  _(Note: May be challenging for local-only network project)_

---

## 7. Data Layer Technologies

### PostgreSQL

#### Connection Pooling

**Use Cases:**

- **Efficient Resource Use:** Reuse connections across requests instead of creating new connections
- **Prevent Connection Exhaustion:** Limit max connections to avoid overwhelming database
- **Graceful Degradation:** Queue requests when all connections busy

#### Read Replicas

**Use Cases:**

- **Reporting Queries (macOS):** Heavy analytics queries run against replica without impacting production
- **Geographic Distribution:** Replica on each Raspberry Pi node for local reads
- **Customer Service Reads:** Fetch user profiles from replica, write loyalty points to primary
- **High Availability:** Automatic failover if primary goes down

#### Query Performance Monitoring

**Use Cases:**

- **Slow Query Detection:** Alert when query takes >100ms
- **Index Optimization:** Identify missing indexes from query plans
- **Query Cost Analysis:** Compare cost of different query approaches
- **Connection Pool Metrics:** Track active/idle/waiting connections

#### Full-Text Search (PostgreSQL FTS)

**Use Cases:**

- **Menu Search (All Apps):** Search "caramel latte" finds "Caramel Macchiato", "Iced Caramel Latte"
- **Order History Search (macOS):** Admin searches orders by customer name, drink type, date range
- **Ingredient Search:** Find drinks containing "vanilla" or "oat milk"
- **Fuzzy Matching:** Typo-tolerant search ("latte" matches "lattee")

#### Alternative: Elasticsearch/Meilisearch

**Use Cases:**

- **Advanced Search:** Faceted search (filter by: drink type, temperature, size, milk options)
- **Search Analytics:** Track popular search terms, failed searches
- **Instant Search:** As-you-type search with <50ms response time
- **Personalized Results:** Boost drinks you've ordered before in search results

### Caching (Valkey)

#### Cache-Aside Pattern

**Use Cases:**

- **Menu Caching:** Check cache for menu, if miss fetch from DB and populate cache
- **User Profiles:** Cache user data with 30-minute TTL
- **Session Data:** Store session info in cache with expiration

#### Write-Through Cache

**Use Cases:**

- **Loyalty Points:** Update both cache and database when points change
- **Real-time Inventory:** Write stock changes to cache + DB simultaneously
- **Order Queue:** New orders written to cache (for fast access) and DB (for durability)

#### Cache Invalidation

**Use Cases:**

- **Menu Updates:** When admin changes menu, invalidate `menu:*` cache keys
- **Profile Changes:** Clear user cache when profile updated
- **Tag-Based Invalidation:** Invalidate all drink caches when ingredient added

#### Cache Warming

**Use Cases:**

- **Startup:** Pre-load popular drinks into cache when service starts
- **Scheduled Refresh:** Warm menu cache every hour before TTL expires
- **Predictive Warming:** Pre-load caches for anticipated traffic (morning rush hour)

#### Hit/Miss Metrics

**Use Cases:**

- **Cache Effectiveness:** Track hit rate (target: >90% for menu queries)
- **TTL Optimization:** Adjust TTL based on hit patterns
- **Cache Size Tuning:** Monitor eviction rates to right-size cache

---

## 8. Event Streaming & Orchestration

### Kafka

**Use Cases:**

- **Event Sourcing:**
  - `OrderPlaced` → Customer Service updates order count
  - `OrderCompleted` → Customer Service increments loyalty points
  - `DrinkPrepared` → Analytics Service records preparation time
- **Service Decoupling:**
  - Order Service publishes events without knowing who consumes them
  - New services can consume historical events by replaying partition
- **Audit Log:**
  - All state changes published to Kafka for compliance/debugging
  - Immutable event log for rebuilding state
- **Fan-out Notifications:**
  - `OrderReady` event consumed by: APNS Service, Live Activity Updater, SMS Service
- **Analytics Pipeline:**
  - Stream events to analytics database for reporting
  - Real-time aggregations (orders per minute, popular drinks)

### Background Jobs (Valkey Queues)

**Use Cases:**

- **APNS Notification Sending:** Enqueue push notifications to avoid blocking request
- **Receipt PDF Generation:** Generate large PDFs asynchronously
- **Image Processing:** Resize/optimize drink photos uploaded to menu
- **Email Sending:** Welcome emails, daily summaries sent via queue
- **Cache Warming:** Background job to refresh popular cache entries
- **Database Cleanup:** Delete old orders, expired sessions periodically

### Scheduled Jobs

**Use Cases:**

- **Daily Summaries:** Every night at 9pm, generate "Today's orders" report for each user
- **Weekly Leaderboard:** Calculate top customers every Monday
- **Loyalty Expiration:** Check for expiring points every day, send reminders
- **Menu Specials:** Activate "Weekend Special" drinks every Friday
- **Backup Jobs:** Database backups scheduled nightly
- **Analytics Aggregation:** Rollup hourly metrics to daily summaries

### Temporal Workflows

#### Coffee Order Workflow

**Use Cases:**

```
Order Placed
  ↓ (start workflow)
Notify Barista (via APNS)
  ↓
Wait for Acceptance (timeout: 5 min)
  ↓ (if accepted)
Update Status: Preparing
  ↓
Wait for Completion Signal
  ↓
Notify Customer: Ready (APNS + Live Activity)
  ↓
Wait for Pickup (timeout: 30 min)
  ↓
Mark Complete
  ↓
Record Stats to Kafka
  ↓ (if timeout)
Cancel & Refund Workflow
```

#### Benefits:

- **State Persistence:** Workflow survives service restarts
- **Timeouts & Retries:** Auto-retry notification sends, timeout if barista doesn't respond
- **Compensation Logic:** Automatic refund if order cancelled mid-flow
- **Long-Running:** Workflows can last 30+ minutes (impossible with HTTP)
- **Visibility:** Temporal UI shows all active orders, where they are in workflow

#### Other Workflow Use Cases:

- **Loyalty Tier Upgrade:** Multi-step workflow to calculate tier, update profile, send congrats notification
- **Subscription Management:** Handle recurring "coffee of the month" subscriptions
- **Inventory Reorder:** Detect low stock → notify admin → wait for approval → submit order
- **User Onboarding:** Multi-day workflow with drip campaign of tutorial notifications

---

## 9. Apple Platform Features

### iOS App (Customer + Barista Dual-Purpose)

#### Live Activities

**Use Cases:**

- **Order Tracking on Lock Screen:**
  - Compact: "hiimtmac is preparing your latte"
  - Expanded: Progress bar, estimated time, barista name, drink photo
  - Dynamic Island: Minimal state (coffee cup filling animation)
- **Live Updates via APNS:** Server pushes updates to Live Activity without app in foreground

#### Home Screen Widgets

**Use Cases:**

- **Small Widget:** Current order status ("Ready for pickup!")
- **Medium Widget:** Active orders list, quick reorder favorite button
- **Large Widget:** Today's order history, loyalty points progress bar
- **Smart Stack Placement:** Widget auto-appears when you order

#### Lock Screen Widgets

**Use Cases:**

- **Inline Widget:** "2 orders today" or "85 loyalty points"
- **Circular Widget:** Coffee cup icon with order count
- **Rectangular Widget:** Last order status

#### Dynamic Island

**Use Cases:**

- **Minimal State:** Coffee cup icon while order in progress
- **Expanded State:** Tap to see preparation step, estimated time
- **Live Updates:** Progress ring fills as drink prepared

#### Siri Shortcuts / App Intents

**Use Cases:**

- **"Order my usual":** Siri places your favorite drink order
- **"What's the status of my order?":** Siri reads order status
- **"Show me the menu":** Siri opens app to menu screen
- **"How many loyalty points do I have?":** Siri responds with count
- **Custom Shortcuts:** Create automation "When I arrive home, show coffee menu"

#### App Clips

**Use Cases:**

- **Guest Ordering:** QR code on kitchen counter → App Clip loads → guest orders without installing full app
- **Quick Access:** Scan NFC tag to instantly open order screen
- **Limited Functionality:** Just ordering, no account features

#### Other Extensions

**Use Cases:**

- **iMessage Extension:** Send drink order to family group chat, collaborate on group order
- **Share Extension:** Share favorite drink recipe via Messages/Mail
- **Photo Editing Extension:** Add coffee stickers/filters to photos (fun!)
- **Action Extension:** "Add to Everything" from photo of drink seen elsewhere
- **Spotlight Search:** Search for drinks from iOS Spotlight

---

### watchOS App

**Use Cases:**

- **Quick Order:** Glance-style interface to reorder favorite drinks
- **Order Status:** Complications showing active order status
- **Notification Actions:** Respond to barista questions from watch notification
- **Handoff:** Start order on watch, continue on iPhone
- **Complications:**
  - Modular: "Order ready" status
  - Circular: Loyalty points progress
  - Utilitarian: Order count today

---

### iPadOS App (POS Terminal)

**Use Cases:**

- **Barista Order Entry:** Take in-person orders with large touch-friendly interface
- **Split View:** Order entry + kitchen queue visible simultaneously
- **Apple Pencil:** Sign drinks with custom messages, mark special requests
- **Drag & Drop:** Drag customizations onto drink orders
- **Multitasking:** Run POS + macOS inventory app side-by-side
- **Stage Manager:** Multiple order windows for busy periods
- **Keyboard Shortcuts:** Power user shortcuts for barista efficiency

---

### macOS App (Admin & Reporting)

**Use Cases:**

- **Menu Management:**
  - Add/edit/remove drinks
  - Upload drink photos (drag & drop)
  - Set pricing, availability, seasonal offerings
  - Manage ingredient inventory
- **Reporting Dashboard:**
  - Charts: Orders over time, popular drinks, revenue
  - Export CSV/PDF reports
  - Filter by date range, customer, drink type
  - Real-time updates via WebSocket
- **Customer Management:**
  - View customer profiles, order history
  - Adjust loyalty points manually
  - Send promotional messages
- **System Monitoring:**
  - View Grafana dashboards embedded
  - Service health status
  - Database/cache metrics
- **Multi-window Support:** Separate windows for different admin tasks
- **Menu Bar App:** Always-accessible quick stats in menu bar

---

### tvOS App (Kitchen Display)

**Use Cases:**

- **Order Queue Display:**
  - Large TV shows all pending orders
  - Color-coded by status (new, in-progress, ready)
  - Auto-refreshes via WebSocket
- **Menu Showcase:**
  - Rotating carousel of drink photos
  - Daily specials highlighted
  - Seasonal offerings
- **Leaderboard:**
  - Top customers this week
  - Most popular drinks
  - Barista efficiency stats
- **Ambient Display:**
  - When idle: Menu showcase mode
  - When busy: Order queue mode
- **Focus Engine:** Navigate with Siri Remote to mark orders complete
- **Picture-in-Picture:** Order queue in corner while showing menu

---

## 10. Development & DevOps

### Server Profiling (swift-profile-recorder)

**Use Cases:**

- **CPU Hotspot Detection:** Record profile of Order Service to find slow code paths
- **Memory Leak Investigation:** Profile memory allocations to find leaks
- **Production Profiling:** Capture profiles in production k3s cluster
- **Performance Comparison:** Compare profiles before/after optimization
- **gRPC Method Profiling:** See which RPC methods use most CPU

### Kubernetes/k3s

**Use Cases:**

- **4-Node Raspberry Pi Cluster:**
  - 1 control plane + 3 workers
  - All services deployed as pods
  - Automatic load balancing across nodes
  - Self-healing: Restart failed pods
- **Service Discovery:** Services find each other via DNS (order-service:50051)
- **Rolling Updates:** Deploy new version with zero downtime
- **Resource Limits:** Prevent one service from consuming all memory
- **Horizontal Scaling:** Scale Order Service to 5 replicas during busy periods
- **Namespace Isolation:** `everything` namespace for apps, `observability` for monitoring
- **Secrets Management:** Store JWT keys, DB passwords securely
- **Persistent Volumes:** Database data survives pod restarts
- **Ingress:** Expose Hummingbird to local network via Tailscale

### CI/CD (GitHub Actions)

**Use Cases:**

- **Automated Builds:** Every commit builds Docker images for changed services
- **ARM64 Cross-Compilation:** Build for Raspberry Pi from GitHub runners
- **Image Publishing:** Push to GitHub Container Registry
- **Path-Based Triggers:** Only rebuild services that changed
- **Multi-Service Pipeline:** Parallel builds for server, order-service, customer-service
- **Automated Testing:** Run tests before building images (future)
- **GitOps Deployment:** Auto-deploy to k3s on successful build (future)
- **Release Tagging:** Semantic versioning, changelog generation

### Analytics Collection & Querying

**Use Cases:**

- **Usage Metrics:**
  - Track screen views, button clicks in iOS app
  - Funnel analysis: Browse menu → Add to cart → Place order
  - A/B testing: Test different menu layouts
- **Business Intelligence:**
  - Customer cohort analysis
  - Retention metrics (daily active users)
  - Revenue analytics
- **Performance Monitoring:**
  - App launch time, screen load time
  - API response time from client perspective
  - Crash reporting
- **Privacy-Focused:** Local analytics database, no third-party services

### DocC & Documentation Hosting

**Use Cases:**

- **API Documentation:**
  - Auto-generated docs from Swift code comments
  - Interactive documentation browser
  - Code examples, tutorials
- **Architecture Decision Records (ADRs):** Document why choices were made
- **Deployment Guides:** Step-by-step k3s setup instructions
- **Onboarding:** New family member guide to using the app
- **Static Site Hosting:** Host on Raspberry Pi cluster with HTTPS

### Foundation Models (LLM Integration)

**Use Cases:**

- **Natural Language Ordering:**
  - "I want a hot caramel drink with oat milk" → Suggests Caramel Macchiato with oat milk
  - Parse voice orders from Siri with context understanding
- **Personalized Recommendations:**
  - "Based on your order history, try this new seasonal latte"
  - LLM generates explanations for recommendations
- **Smart Search:**
  - "Something sweet and cold" → Returns iced mochas, frappuccinos
  - Semantic search beyond keyword matching
- **Recipe Generation:**
  - "Create a new drink using vanilla, cinnamon, and espresso"
  - LLM suggests proportions and preparation steps
- **Customer Support Chat:**
  - Answer FAQs about menu, ingredients, preparation time
  - Handle special requests, dietary restrictions

---

## 11. Future Technologies

### Distributed Actors

**Use Cases:**

- **Order Actor:** Single actor instance representing each order, distributed across cluster
- **Customer Actor:** Actor per customer managing their session state
- **Barista Actor:** Actor representing each barista with their work queue
- **Location Transparency:** Call actor methods without knowing which node it's on
- **Actor Migration:** Move hot actors to less-loaded nodes
- **Strong Isolation:** Each order's state completely isolated from others

### Embedded Swift

**Use Cases:**

- **IoT Devices:**
  - Smart coffee machine integration (if you had one!)
  - Raspberry Pi Zero sensors (temperature, humidity monitoring)
  - Custom hardware POS terminals
- **Minimal Footprint:** Swift code on microcontrollers
- **Real-time Control:** Direct hardware control from Swift

### WebAssembly (WASM) Swift

**Use Cases:**

- **Web Admin Panel:** Swift backend logic running in browser
- **Shared Business Logic:** Run validation/calculation logic in web and native apps
- **Offline-First Web App:** WASM-powered web app works offline
- **Edge Computing:** Run Swift code on Cloudflare Workers (if you wanted external access)

### Swift for Android

**Use Cases:**

- **Shared Client Library:**
  - Compile `OpenAPIClient` to run on Android
  - Share models, networking, business logic
  - Native UI (Kotlin) but Swift for data layer
- **Cross-Platform Consistency:** Same API client behavior on iOS and Android
- **Future Android App:** Build Android version for non-Apple family members

### CoreML with Background Tasks

**Use Cases:**

- **Drink Recommendation Model:**
  - Train model on order history
  - Predict which drink you'll want based on time of day, weather, recent orders
  - Update model nightly via background task
- **Personalized Search Ranking:**
  - Model learns which search results you click
  - Re-ranks results personalized to you
- **Demand Forecasting:**
  - Predict how many orders to expect tomorrow
  - Help barista prepare inventory
- **Anomaly Detection:**
  - Detect unusual ordering patterns (potential account compromise)
  - Flag suspicious activity for review

---

## Feature Integration Examples

### Example 1: End-to-End Order Flow (Using Multiple Technologies)

**Customer places order from iPhone:**

1. **iOS App** - SwiftUI with App Intents ("Order my usual")
2. **OpenAPI Client** - Generated REST client sends POST /orders
3. **QUIC** - Fast connection to Hummingbird server
4. **Hummingbird** - JWT validation, protocol translation
5. **Unary gRPC** - Hummingbird calls Order Service `PlaceOrder()`
6. **PostgreSQL** - Order Service writes to OrderDB
7. **Temporal Workflow** - Order Service starts `CoffeeOrderWorkflow`
8. **Kafka** - Publish `OrderPlaced` event
9. **Valkey Queue** - Enqueue APNS notification job
10. **APNS** - Send push + start Live Activity
11. **Live Activity** - Updates on iPhone lock screen
12. **WebSocket** - Barista macOS app receives real-time update
13. **Distributed Tracing** - Full request traced across all services
14. **Grafana** - Metrics recorded (order_count++, latency histogram)

**Barista accepts order:** 15. **macOS App** - Barista clicks "Accept" 16. **GraphQL Mutation** - `acceptOrder(id: "123")` 17. **Bidirectional gRPC** - Real-time stream to Order Service 18. **Temporal Signal** - Workflow receives acceptance signal 19. **Server Streaming gRPC** - Order Service streams preparation steps to barista app 20. **APNS** - Update customer's Live Activity ("hiimtmac is making your latte") 21. **Dynamic Island** - Progress animation on iPhone

**Order ready:** 22. **Temporal Activity** - Workflow executes `NotifyCustomer` activity 23. **Kafka** - Publish `OrderReady` event 24. **SSE** - Stream status update to all connected devices 25. **APNS Rich Notification** - Notification with drink photo 26. **tvOS Display** - Kitchen TV updates queue 27. **watchOS Complication** - Watch shows "Order Ready"

### Example 2: Multi-Platform Admin Experience

**Admin manages menu from macOS:**

1. **macOS App** - Admin uploads new drink photo
2. **Client Streaming gRPC** - Stream photo chunks to server
3. **Background Job** - Enqueue image processing (resize, optimize)
4. **PostgreSQL** - Write new menu item to OrderDB
5. **Cache Invalidation** - Clear Valkey `menu:*` keys
6. **Kafka** - Publish `MenuUpdated` event
7. **SSE** - Notify all connected iOS/watchOS/tvOS apps
8. **WebSocket** - Real-time update to other macOS admin instances
9. **Read Replica** - Analytics queries use replica
10. **Full-Text Search** - Reindex new drink in PostgreSQL FTS

**Mobile apps react:** 11. **Silent APNS** - Wake iOS apps to refresh cache 12. **Background Fetch** - iOS downloads new menu 13. **Widget Update** - Home screen widget shows new drink 14. **tvOS Refresh** - Kitchen TV menu carousel adds new drink 15. **App Clips** - Guest ordering QR code shows updated menu

### Example 3: Advanced Authentication Journey

**New user signs up:**

1. **iOS App** - User taps "Sign up with passkey"
2. **WebAuthn** - Generate passkey with Face ID
3. **Unary gRPC** - Register passkey challenge to Customer Service
4. **PostgreSQL** - Store passkey credential in CustomerDB
5. **JWT** - Server returns signed access token
6. **Session Management** - Store session in Valkey
7. **GraphQL** - Fetch user profile with single query

**User enables 2FA:** 8. **TOTP Setup** - Generate QR code for Google Authenticator 9. **OTP Verification** - User confirms 6-digit code 10. **SRP** - Setup SRP credentials as backup auth method

**Suspicious login detected:** 11. **Analytics** - ML model flags login from new device 12. **SMS OTP** - Require additional verification 13. **Kafka Event** - Log security event for audit 14. **APNS** - Send "New device login" alert to trusted device

**User switches to Sign in with Apple:** 15. **OAuth2/OIDC** - Initiate SIWA flow (if feasible for local network) 16. **JWT Claims** - Map Apple ID to existing account 17. **Multi-factor** - Optionally still require passkey for sensitive actions

---

## Summary: Technology Coverage

This architecture uses:

- ✅ **6 real-time protocols** (WebSocket, SSE, HTTP Streaming, QUIC, gRPC streaming, GraphQL subscriptions)
- ✅ **4 gRPC patterns** (Unary, Server Stream, Client Stream, Bidirectional)
- ✅ **7 auth methods** (Passkeys, JWT, TOTP, SRP, Basic, Session, OAuth2)
- ✅ **5 database patterns** (Connection pool, read replicas, FTS, query monitoring, caching)
- ✅ **6 cache strategies** (Cache-aside, write-through, invalidation, warming, hit/miss metrics, TTL tuning)
- ✅ **3 event/workflow patterns** (Kafka event streaming, background jobs, Temporal workflows)
- ✅ **15+ iOS features** (Live Activities, Widgets, Dynamic Island, App Intents, App Clips, Extensions, etc.)
- ✅ **5 platforms** (iOS, watchOS, iPadOS, macOS, tvOS)
- ✅ **Full observability** (Distributed tracing, metrics, logs, visualization)
- ✅ **Modern DevOps** (k3s, CI/CD, profiling, analytics, documentation)
- ✅ **Future tech** (Distributed Actors, Embedded Swift, WASM, Android, CoreML, LLMs)

Every technology serves a clear purpose and integrates cohesively into the coffee ordering system. This is intentionally over-engineered for learning, but each piece demonstrates real-world patterns applicable to production systems.

---
