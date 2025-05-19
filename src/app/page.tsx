'use client'

import { useEffect, useState } from "react"

export default function Home() {
  const [apiStatus, setApiStatus] = useState<boolean|null>(null)
  
  useEffect(() => {
    const checkHealth = async () => {
      try {
        const response = await fetch('http://localhost:8000/')
        setApiStatus(response.ok)
      } catch (error) {
        console.log(error)
        setApiStatus(false)
      }
    }

    checkHealth()
    const interval = setInterval(checkHealth, 5000)

    return () => clearInterval(interval)
  }, [])
  
  return (
    <main>
      <h1>Welcome to CloudWeave!</h1>
      <p>Application Status:</p>
      {apiStatus === null ? (
        <p>Checking API...</p>
      ) : apiStatus ? (
        <p>API connected ✅</p>
      ) : (
        <p>API can&apos;t be reached ❌</p>
      )}
    </main>
  );
}
