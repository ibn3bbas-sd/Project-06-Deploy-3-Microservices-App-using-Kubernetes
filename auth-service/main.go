package main

import (
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
    httpDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "http_request_duration_seconds",
            Help:    "Duration of HTTP requests",
            Buckets: prometheus.DefBuckets,
        },
        []string{"method", "route", "status_code"},
    )
)

func init() {
    prometheus.MustRegister(httpDuration)
}

type Claims struct {
    Username string `json:"username"`
    jwt.RegisteredClaims
}

var jwtSecret = []byte("your-secret-key-from-k8s-secret")

func main() {
    router := gin.Default()

    // Health endpoints
    router.GET("/health/live", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{"status": "alive"})
    })

    router.GET("/health/ready", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{"status": "ready"})
    })

    // Metrics endpoint
    router.GET("/metrics", gin.WrapH(promhttp.Handler()))

    // Authentication endpoints
    router.POST("/login", login)
    router.POST("/validate", validateToken)

    router.Run(":8080")
}

func login(c *gin.Context) {
    timer := prometheus.NewTimer(httpDuration.WithLabelValues("POST", "/login", "200"))
    defer timer.ObserveDuration()

    var loginReq struct {
        Username string `json:"username" binding:"required"`
        Password string `json:"password" binding:"required"`
    }

    if err := c.ShouldBindJSON(&loginReq); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    // Simple validation (replace with real auth)
    if loginReq.Username == "admin" && loginReq.Password == "password" {
        claims := &Claims{
            Username: loginReq.Username,
            RegisteredClaims: jwt.RegisteredClaims{
                ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
                IssuedAt:  jwt.NewNumericDate(time.Now()),
            },
        }

        token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
        tokenString, err := token.SignedString(jwtSecret)

        if err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
            return
        }

        c.JSON(http.StatusOK, gin.H{
            "token": tokenString,
            "user":  loginReq.Username,
        })
    } else {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
    }
}

func validateToken(c *gin.Context) {
    var req struct {
        Token string `json:"token" binding:"required"`
    }

    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    tokenString := req.Token
    if len(tokenString) > 7 && tokenString[:7] == "Bearer " {
        tokenString = tokenString[7:]
    }

    claims := &Claims{}
    token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
        return jwtSecret, nil
    })

    if err != nil || !token.Valid {
        c.JSON(http.StatusOK, gin.H{"valid": false})
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "valid": true,
        "user":  claims.Username,
    })
}