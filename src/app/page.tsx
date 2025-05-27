'use client'

import { gql, useQuery } from "@apollo/client"

const HEALTH_CHECK_QUERY = gql`
  query {
    __typename
  }
`

export default function Home() {
  const { data, loading, error } = useQuery(HEALTH_CHECK_QUERY, {
    pollInterval: 5000
  })

  const apiStatus = !loading && !error
  
  return (
    <main>
      <h1>Welcome to CloudWeave!</h1>
      <p>Application Status:</p>
      {loading ? (
        <p>Checking API...</p>
      ) : apiStatus ? (
        <p>API connected ✅</p>
      ) : (
        <p>API can&apos;t be reached ❌</p>
      )}
    </main>
  );
}
